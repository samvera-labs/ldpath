require 'spec_helper'
require 'pp'
describe Ldpath::Transform do
  let(:parser) { Ldpath::Parser.new }
  it "should transform literals" do
    subject.apply(literal: "xyz")
  end
  
  it "should transform uris" do
    actual = subject.apply(iri: "info:a")
    expect(actual).to eq RDF::URI.new("info:a")
  end
  
  it "should transform prefix + localNames" do
    actual = subject.apply(prefix: "rdf", localName:"type")
    expect(actual).to eq RDF.type
  end
  
  it "should transform mappings" do
    actual = subject.apply parser.parse("x = . ;")
    expect(actual.length).to eq 1
    mapping = actual.first
    expect(mapping).to be_a_kind_of Ldpath::FieldMapping
    expect(mapping.name).to eq "x"
    expect(mapping.selector).to be_a_kind_of Ldpath::SelfSelector
  end
  
  it "should transform wildcards" do
    actual = subject.apply parser.parse("xyz = * ;\n")

    mapping = actual.first
    expect(mapping).to be_a_kind_of Ldpath::FieldMapping
    expect(mapping.name).to eq "xyz"
    expect(mapping.selector).to be_a_kind_of Ldpath::WildcardSelector
  end
  
  it "should transform reverse properties" do
    actual = subject.apply parser.parse("xyz = ^info:a ;\n")

    mapping = actual.first
    expect(mapping).to be_a_kind_of Ldpath::FieldMapping
    expect(mapping.name).to eq "xyz"
    expect(mapping.selector).to be_a_kind_of Ldpath::ReversePropertySelector
    expect(mapping.selector.property).to eq RDF::URI.new("info:a")
  end
  
  describe "recursive properties" do
    it "is a zero-or-one matcher" do
      actual = subject.apply parser.parse("xyz = (info:a)? ;\n")
      selector = actual.first.selector
      expect(selector).to be_a_kind_of Ldpath::RecursivePathSelector
      expect(selector.property.property).to eq RDF::URI.new("info:a")
      expect(selector.repeat).to eq 0..1
    end

    it "is a 0-to-infinity matcher" do
      actual = subject.apply parser.parse("xyz = (info:a)* ;\n")

      selector = actual.first.selector
      expect(selector).to be_a_kind_of Ldpath::RecursivePathSelector
      expect(selector.property.property).to eq RDF::URI.new("info:a")
      expect(selector.repeat).to eq 0..Ldpath::Transform::Infinity
    end

    it "is a 1-to-infinity matcher" do
      actual = subject.apply parser.parse("xyz = (info:a)+ ;\n")

      selector = actual.first.selector
      expect(selector).to be_a_kind_of Ldpath::RecursivePathSelector
      expect(selector.property.property).to eq RDF::URI.new("info:a")
      expect(selector.repeat).to eq 1..Ldpath::Transform::Infinity
    end

    it "is a 0 to 5 matcher" do
      actual = subject.apply parser.parse("xyz = (info:a){,5} ;\n")

      selector = actual.first.selector
      expect(selector).to be_a_kind_of Ldpath::RecursivePathSelector
      expect(selector.property.property).to eq RDF::URI.new("info:a")
      expect(selector.repeat).to eq 0..5
    end

    it "is a 2 to 5 matcher" do
      actual = subject.apply parser.parse("xyz = (info:a){2,5} ;\n")

      selector = actual.first.selector
      expect(selector).to be_a_kind_of Ldpath::RecursivePathSelector
      expect(selector.property.property).to eq RDF::URI.new("info:a")
      expect(selector.repeat).to eq 2..5
    end

    it "is a 2 to infinity matcher" do
      actual = subject.apply parser.parse("xyz = (info:a){2,} ;\n")

      selector = actual.first.selector
      expect(selector).to be_a_kind_of Ldpath::RecursivePathSelector
      expect(selector.property.property).to eq RDF::URI.new("info:a")
      expect(selector.repeat).to eq 2..Ldpath::Transform::Infinity
    end
  end

  it "should transform tap selectors" do
    actual = subject.apply parser.parse("xyz = ?<x>info:a ;\n")

    selector = actual.first.selector
    expect(selector).to be_a_kind_of Ldpath::TapSelector
    expect(selector.identifier).to eq "x"
    expect(selector.tap).to be_a_kind_of Ldpath::PropertySelector
  end
  
  it "should transform loose property selectors" do
    actual = subject.apply parser.parse("xyz = ~info:a ;\n")

    selector = actual.first.selector
    expect(selector).to be_a_kind_of Ldpath::LoosePropertySelector
    expect(selector.property).to eq RDF::URI.new("info:a")
  end

  it "should transform namespaces" do
    actual = subject.apply parser.parse("@prefix xyz: <info:xyz>")
    expect(subject.prefixes).to include "xyz"
    expect(subject.prefixes["xyz"].to_s).to eq "info:xyz"
  end
  
  it "should transform path selectors" do
    actual = subject.apply parser.parse("x = info:a / . ;")

    selector = actual.first.selector
    expect(selector).to be_a_kind_of Ldpath::PathSelector
    expect(selector.left).to be_a_kind_of Ldpath::PropertySelector
    expect(selector.right).to be_a_kind_of Ldpath::SelfSelector
  end
  
  it "should transform functions" do
    selector = subject.apply parser.function_selector.parse("fn:concat(foaf:givename,\" \",foaf:surname)")

    expect(selector).to be_a_kind_of Ldpath::FunctionSelector
    expect(selector.fname).to eq "concat"
    expect(selector.arguments.length).to eq 3
  end

  it "should transform the foaf example" do
    subject.apply parser.parse(File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "foaf_example.program")))
)
  end
  
  it "should parse the program.ldpath" do
    subject.apply parser.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "program.ldpath")))
  end

end
