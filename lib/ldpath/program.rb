module Ldpath
  class Program

    include Ldpath::Functions

    class << self
      def parse program, transform_context = {}
        parsed = parser.parse(program)
        ast = transform.apply parsed, transform_context

        Ldpath::Program.new ast.compact
      end

      private
      def transform
        Ldpath::Transform.new
      end

      def parser
        @parser ||= Ldpath::Parser.new
      end
    end
    
    attr_reader :mappings
    def initialize mappings
      @mappings ||= mappings
      @cache = {}
    end
    
    def loading uri, context
      if uri.to_s =~ /^http/ and !context.has_subject?(uri)
        @cache[uri] ||= RDF::Graph.load(uri)
        context << @cache[uri]
      end
    end

    def evaluate uri, context = nil
      h = {}
      context ||= RDF::Graph.load uri.to_s

      mappings.each do |m|
        h[m.name] = m.selector.evaluate(self, uri, context).map do |x| 
          next x unless m.field_type
          RDF::Literal.new(x.to_s, datatype: m.field_type).canonicalize.object
        end
      end

      h
    end
    
    def func_call fname, uri, context, *arguments
      if function_method? fname
        public_send(fname, uri, context, *arguments)
      else
        raise "No such function: #{fname}"
      end
    end

    private
    def function_method? function
      Functions.public_instance_methods(false).include? function.to_sym
    end

  end
end
