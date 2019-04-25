module Ldpath
  class Program
    ParseError = Class.new StandardError

    class << self
      def parse(program, transform_context = {})
        ast = transform.apply load(program), transform_context

        Ldpath::Program.new ast.compact, transform_context
      end

      def load(program)
        parser.parse(program, reporter: Parslet::ErrorReporter::Deepest.new)
      rescue Parslet::ParseFailed => e
        raise ParseError, e.parse_failure_cause.ascii_tree
      end

      private

      def transform
        Ldpath::Transform.new
      end

      def parser
        @parser ||= Ldpath::Parser.new
      end
    end

    attr_reader :mappings, :prefixes, :filters, :loader
    def initialize(mappings, options = {})
      @mappings ||= mappings
      @loader = options[:loader] || Ldpath::Loaders::Direct.new
      @prefixes = options[:prefixes] || {}
      @filters = options[:filters] || []
    end

    def evaluate(uri, context: nil, limit_to_context: false)
      result = Ldpath::Result.new(self, uri, context: context, limit_to_context: limit_to_context)
      unless filters.empty?
        return {} unless filters.all? { |f| f.evaluate(result, uri, result.context) }
      end

      result.to_hash
    end

    def load(uri)
      loader.load(uri)
    end
  end
end
