require 'spec_helper'

describe Ldpath::Program do
  describe "Simple program" do
    subject do
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = dcterms:title :: xsd:string ;
EOF
    end
    
    it "should work" do
      uri = RDF::URI.new("info:a")
      graph = RDF::Graph.new << [uri, RDF::DC.title, "Hello, world!"]
      result = subject.evaluate uri, graph
      
      expect(result["title"]).to include "Hello, world!"
    end
  end
end
