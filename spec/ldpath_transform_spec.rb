require 'spec_helper'
require 'pp'
describe Ldpath::Transform do
  let(:parser) { Ldpath::Parser.new }
  it "should transform literals" do
    subject.apply(literal: "xyz")
  end
  
  it "should transform uris" do
    subject.apply(uri:"http://www.w3.org/2003/01/geo/wgs84_pos#")
  end
  
  it "should transform nested uris" do
    subject.apply(uri: { uri: "info:a"})
  end
  
  it "should transform prefix + localNames" do
    subject.apply(prefix: "info", localName:"a")
  end
  
  it "should transform mappings" do
    subject.apply parser.parse("x = . ;")
  end
  
  it "should transform wildcards" do
    subject.apply parser.parse("xyz = * ;\n")
  end
  
  it "should transform reverse properties" do
    subject.apply parser.parse("xyz = ^info:a ;\n")
  end
  
  it "should transform recursive properties" do
    subject.apply parser.parse("xyz = (info:a)* ;\n")
    subject.apply parser.parse("xyz = (info:a)+ ;\n")
    subject.apply parser.parse("xyz = (info:a){,5} ;\n")
    subject.apply parser.parse("xyz = (info:a){2,5} ;\n")
    subject.apply parser.parse("xyz = (info:a){2,} ;\n")
  end
  
  it "should transform tap selectors" do
    subject.apply parser.parse("xyz = ?<x>info:a ;\n")
  end

  it "should transform namespaces" do
    subject.apply parser.parse("@prefix foaf: <http://xmlns.com/foaf/0.1/>")
  end
  
  it "should transform path selectors" do
    subject.apply parser.parse("x = . / . ;")
  end
  
  it "should transform functions" do
    subject.apply parser.function_selector.parse("fn:concat(foaf:givename,\" \",foaf:surname)")
  end
  
  it "should transform the foaf example" do
    subject.apply parser.parse(File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "foaf_example.program")))
)
  end
  
  it "should parse the program.ldpath" do
    subject.apply parser.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "program.ldpath")))
  end

end
