module Ldpath
  class Program
    class << self
      def parse program
        parsed = parser.parse(program)
        ast = transform.apply parsed

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
    end

    def evaluate uri, context = nil
      h = {}
      context ||= RDF::Graph.new

      mappings.each do |m|
        h[m.name] = m.selector.evaluate(uri, context).map do |x| 
          next x unless m.field_type
          RDF::Literal.new(x.to_s, datatype: m.field_type).canonicalize.object
        end
      end

      h
    end

  end
end
