require 'spec_helper'

describe Ldpath::Program do
  describe "Simple program" do
    subject do
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = dcterms:title :: xsd:string ;
parent_title = dcterms:isPartOf / dcterms:title :: xsd:string ;
titles = dcterms:title | (dcterms:isPartOf / dcterms:title) | (^dcterms:isPartOf / dcterms:title) :: xsd:string ;
no_titles = dcterms:title & (dcterms:isPartOf / dcterms:title) & (^dcterms:isPartOf / dcterms:title) :: xsd:string ;
self = . :: xsd:string ;
wildcard = * ::xsd:string ;
child_title = ^dcterms:isPartOf / dcterms:title :: xsd:string ;
recursive = (dcterms:isPartOf)* ;
en_description = dcterms:description[@en] ;
conditional = dcterms:isPartOf[dcterms:title] ;
conditional_false = dcterms:isPartOf[dcterms:description] ;
int_value = <info:intProperty>[^^xsd:integer] :: xsd:integer ;
numeric_value = <info:numericProperty> :: xsd:integer ;
escaped_string = "\\"" :: xsd:string;
and_test = .[dcterms:title & dcterms:gone] ;
or_test = .[dcterms:title | dcterms:gone] ;
is_test = .[dcterms:title is "Hello, world!"] ;
is_not_test = .[!(dcterms:title is "Hello, world!")] ;
EOF
    end
    
    let(:object) { RDF::URI.new("info:a") }
    let(:parent) { RDF::URI.new("info:b") }
    let(:child) { RDF::URI.new("info:c") }
    let(:grandparent) { RDF::URI.new("info:d") }
    
    let(:graph) do
      RDF::Graph.new
    end
    
    it "should work" do
      graph << [object, RDF::DC.title, "Hello, world!"]
      graph << [object, RDF::DC.isPartOf, parent]
      graph << [object, RDF::DC.description, RDF::Literal.new("English!", language: "en")]
      graph << [object, RDF::DC.description, RDF::Literal.new("French!", language: "fr")]
      graph << [object, RDF::URI.new("info:intProperty"), 1]
      graph << [object, RDF::URI.new("info:intProperty"), "garbage"]
      graph << [object, RDF::URI.new("info:numericProperty"), "1"]
      graph << [parent, RDF::DC.title, "Parent title"]
      graph << [child, RDF::DC.isPartOf, object]
      graph << [child, RDF::DC.title, "Child title"]
      graph << [parent, RDF::DC.isPartOf, grandparent]

      result = subject.evaluate object, graph

      expect(result["title"]).to match_array "Hello, world!"
      expect(result["parent_title"]).to match_array "Parent title"
      expect(result["self"]).to match_array(object)
      expect(result["wildcard"]).to include "Hello, world!", parent
      expect(result["child_title"]).to match_array "Child title"
      expect(result["titles"]).to match_array ["Hello, world!", "Parent title", "Child title"]
      expect(result["no_titles"]).to be_empty
      expect(result["recursive"]).to match_array [parent, grandparent]
      expect(result["en_description"].first.to_s).to eq "English!"
      expect(result["conditional"]).to match_array parent
      expect(result["conditional_false"]).to be_empty
      expect(result["int_value"]).to match_array 1
      expect(result["numeric_value"]).to match_array 1
      expect(result["escaped_string"]).to match_array '\"'
      expect(result["and_test"]).to be_empty
      expect(result["or_test"]).to match_array(object)
      expect(result["is_test"]).to match_array(object)
      expect(result["is_not_test"]).to be_empty
    end
  end
  
  describe "functions" do
    
      subject do
        Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = fn:concat("a", "b") ;
first_a = fn:first("a", "b") ;
last_b = fn:last("a", "b") ;
EOF
      end

      let(:object) { RDF::URI.new("info:a") }
      
      let(:graph) do
        RDF::Graph.new
      end
      
    it "should work" do
      result = subject.evaluate object, graph
      expect(result["title"]).to match_array "ab"
      expect(result["first_a"]).to match_array "a"
      expect(result["last_b"]).to match_array "b"
      
    end
  end
  
  describe "Data loading" do
    subject do
      
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = foaf:primaryTopic / dc:title :: xsd:string ;
EOF
      
    end
    
    it "should work" do
      result = subject.evaluate RDF::URI.new("http://www.bbc.co.uk/programmes/b0081dq5.rdf")
      expect(result["title"]).to match_array "Huw Stephens"
    end
  end
end
