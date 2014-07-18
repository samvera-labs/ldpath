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
EOF
    end
    
    it "should work" do
      uri = RDF::URI.new("info:a")
      uri_b = RDF::URI.new("info:b")
      uri_c = RDF::URI.new("info:c")
      graph = RDF::Graph.new << [uri, RDF::DC.title, "Hello, world!"]
      graph << [uri, RDF::DC.isPartOf, uri_b]
      graph << [uri_b, RDF::DC.title, "Parent title"]
      graph << [uri_c, RDF::DC.isPartOf, uri]
      graph << [uri_c, RDF::DC.title, "Child title"]
      result = subject.evaluate uri, graph

      expect(result["title"]).to match_array "Hello, world!"
      expect(result["parent_title"]).to match_array "Parent title"
      expect(result["self"]).to match_array(uri)
      expect(result["wildcard"]).to match_array ["Hello, world!", uri_b]
      expect(result["child_title"]).to match_array "Child title"
      expect(result["titles"]).to match_array ["Hello, world!", "Parent title", "Child title"]
      expect(result["no_titles"]).to be_empty
    end
  end
end
