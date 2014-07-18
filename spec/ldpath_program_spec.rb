require 'spec_helper'

describe Ldpath::Program do
  describe "Simple program" do
    subject do
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = dcterms:title :: xsd:string ;
parent_title = dcterms:isPartOf / dcterms:title :: xsd:string ;
EOF
    end
    
    it "should work" do
      uri = RDF::URI.new("info:a")
      uri_b = RDF::URI.new("info:b")
      graph = RDF::Graph.new << [uri, RDF::DC.title, "Hello, world!"]
      graph << [uri, RDF::DC.isPartOf, uri_b]
      graph << [uri_b, RDF::DC.title, "Parent title"]
      result = subject.evaluate uri, graph
      
      expect(result["title"]).to match_array "Hello, world!"
      expect(result["parent_title"]).to match_array "Parent title"
    end
  end
end
