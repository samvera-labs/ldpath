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
      graph << [parent, RDF::DC.title, "Parent title"]
      graph << [child, RDF::DC.isPartOf, object]
      graph << [child, RDF::DC.title, "Child title"]
      graph << [parent, RDF::DC.isPartOf, grandparent]
      result = subject.evaluate object, graph

      expect(result["title"]).to match_array "Hello, world!"
      expect(result["parent_title"]).to match_array "Parent title"
      expect(result["self"]).to match_array(object)
      expect(result["wildcard"]).to match_array ["Hello, world!", parent]
      expect(result["child_title"]).to match_array "Child title"
      expect(result["titles"]).to match_array ["Hello, world!", "Parent title", "Child title"]
      expect(result["no_titles"]).to be_empty
      expect(result["recursive"]).to match_array [parent, grandparent]
    end
  end
end
