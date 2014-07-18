module Ldpath
  class Transform < Parslet::Transform
    
    def self.default_prefixes
    @default_prefixes ||= {
      "rdf"  => RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#"),
      "rdfs" => RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#"),
      "owl"  => RDF::Vocabulary.new("http://www.w3.org/2002/07/owl#"),
      "skos" => RDF::Vocabulary.new("http://www.w3.org/2004/02/skos/core#"),
      "dc"   => RDF::Vocabulary.new("http://purl.org/dc/elements/1.1/"),
      "xsd"  => RDF::Vocabulary.new("http://www.w3.org/2001/XMLSchema#"),#          (LMF base index datatypes/XML Schema)
      "lmf"  => RDF::Vocabulary.new("http://www.newmedialab.at/lmf/types/1.0/"),#    (LMF extended index datatypes)
      "fn"   => RDF::Vocabulary.new("http://www.newmedialab.at/lmf/functions/1.0/"),# (LMF index functions)
      "foaf" => RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/"),
      "info" => RDF::Vocabulary.new("info:"),
      "urn" => RDF::Vocabulary.new("urn:"),
    }
    end

    def apply obj, context = nil
      context ||= { }
      context[:prefixes] ||= {}.merge(self.class.default_prefixes)
      super obj, context
    end
    
    # Core types
    rule(literal: simple(:literal)) { literal.to_s }
    rule(uri: simple(:uri)) { RDF::URI.new(uri) }
    rule(lang: simple(:lang)) { { lang: lang.to_s } }
    
    # Namespaces
    rule(namespace: subtree(:namespace)) do
      prefixes[namespace[:id].to_s] = RDF::Vocabulary.new(namespace[:uri])
      nil
    end
    
    rule(prefix: simple(:prefix), localName: simple(:localName)) do
      prefixes[prefix.to_s][localName]
    end
    
    # Mappings
    class FieldMapping < Struct.new(:name, :selector, :field_type)
    end
    
    rule(mapping: subtree(:mapping)) do
      FieldMapping.new mapping[:name].to_s, mapping[:selector], mapping[:field_type]
    end

    ## Selectors
    
    
    ### Atomic Selectors
    rule(self: simple(:self)) { "self-selector" }
  
    class FunctionSelector < Struct.new(:fname, :arguments)
      
    end

    rule(fname: simple(:fname), arglist: subtree(:arglist)) do
      FunctionSelector.new fname.to_s, arglist
    end

    class PropertySelector < Struct.new(:property)
      def evaluate uri, context
        context.query([uri, property, nil]).each_object
      end
    end
  
    rule(property: simple(:property)) do
      PropertySelector.new property
    end
    
    class WildcardSelector
    end
    
    rule(wildcard: simple(:wilcard)) do
      WildcardSelector.new
    end
    
    class ReversePropertySelector < Struct.new(:property)
    end
    
    rule(reverse_property: simple(:property)) do
      ReversePropertySelector.new property
    end
    
    class RecursivePathSelector < Struct.new(:property, :repeat)
    end
    
    rule(range: subtree(:range)) do
      range.fetch(:min,0).to_i..range.fetch(:max, 1.0 / 0.0).to_f
    end
    
    rule(recursive: subtree(:properties)) do
      repeat = case properties[:repeat]
      when "*"
        0..(1.0 / 0.0)
      when "+"
        1..(1.0 / 0.0)
      when Range
        properties[:repeat]
      end

      RecursivePathSelector.new properties[:delegate], repeat  
    end
  
    ### Test Selectors
    class TestSelector < Struct.new(:delegate, :test)
    end

    rule(delegate: subtree(:delegate), test: subtree(:test)) do
      TestSelector.new delegate, test
    end


    ## Compound Selectors
    class PathSelector < Struct.new(:left, :right)
    end
    
    class UnionSelector < Struct.new(:left, :right)
    end

    class IntersectionSelector < Struct.new(:left, :right)
    end
    
    rule(path: subtree(:path)) do
      PathSelector.new path[:left], path[:right]
    end
    
    rule(union: subtree(:union)) do
      UnionSelector.new union[:left], union[:right]
    end
    
    rule(intersection: subtree(:intersection)) do
      IntersectionSelector.new intersection[:left], intersection[:right]
    end

 end
end
