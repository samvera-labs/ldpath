module Ldpath
  class Transform < Parslet::Transform

    class << self
      def default_prefixes
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
    end

    def apply obj, context = nil
      context ||= { }
      context[:prefixes] ||= {}.merge(self.class.default_prefixes)
      super obj, context
    end
    
    # Core types
    rule(literal: simple(:literal)) { literal.to_s }
    rule(uri: simple(:uri)) { RDF::URI.new(uri) }
    
    # Namespaces
    rule(namespace: subtree(:namespace)) do
      prefixes[namespace[:id].to_s] = RDF::Vocabulary.new(namespace[:uri])
      nil
    end
    
    rule(prefix: simple(:prefix), localName: simple(:localName)) do
      (prefixes[prefix.to_s] || RDF::Vocabulary.new(prefix.to_s))[localName]
    end

    # Mappings
    
    rule(mapping: subtree(:mapping)) do
      FieldMapping.new mapping[:name].to_s, mapping[:selector], mapping[:field_type]
    end

    ## Selectors
    
    
    ### Atomic Selectors
    rule(self: simple(:self)) do 
      SelfSelector.new
    end

    rule(fname: simple(:fname), arglist: subtree(:arglist)) do
      FunctionSelector.new fname.to_s, arglist
    end
  
    rule(property: simple(:property)) do
      PropertySelector.new property
    end

    rule(wildcard: simple(:wilcard)) do
      WildcardSelector.new
    end

    rule(reverse_property: simple(:property)) do
      ReversePropertySelector.new property
    end

    rule(range: subtree(:range)) do
      range.fetch(:min,0).to_i..range.fetch(:max, Infinity).to_f
    end
    
    rule(recursive: subtree(:properties)) do
      repeat = case properties[:repeat]
      when "*"
        0..Infinity
      when "+"
        1..Infinity
      when Range
        properties[:repeat]
      end

      RecursivePathSelector.new properties[:delegate], repeat  
    end
  
    ### Test Selectors

    rule(delegate: subtree(:delegate), test: subtree(:test)) do
      TestSelector.new delegate, test
    end

    rule(lang: simple(:lang)) do
      LanguageTest.new lang.to_s.to_sym
    end

    rule(type: simple(:type)) do
      TypeTest.new type
    end

    rule(type: simple(:type)) do
      TypeTest.new type
    end
    
    rule(not: subtree(:not_op)) do
      NotTest.new not_op[:delegate]
    end
    
    rule(and: subtree(:op)) do
      AndTest.new op[:left], op[:right]
    end
    
    rule(or: subtree(:op)) do
      OrTest.new op[:left], op[:right]
    end

    rule(is: subtree(:is)) do
      IsTest.new PropertySelector.new(is[:property]), is[:right]
    end
    
    rule(is_a: subtree(:is_a)) do
      IsTest.new PropertySelector.new(RDF.type), is_a[:right]
    end
    ### Compound Selectors
    
    rule(path: subtree(:path)) do
      PathSelector.new path[:left], path[:right]
    end
    
    rule(union: subtree(:union)) do
      UnionSelector.new union[:left], union[:right]
    end
    
    rule(intersection: subtree(:intersection)) do
      IntersectionSelector.new intersection[:left], intersection[:right]
    end


    Infinity = 1.0 / 0.0
  end
end
