module Ldpath
  class Program
    class << self
      def parse program
        ast = transform.apply parser.parse(program)

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
        h[m.name] = m.selector.evaluate(uri, context)
      end

      h
    end

  end
end
