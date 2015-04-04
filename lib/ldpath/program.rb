module Ldpath
  class Program

    include Ldpath::Functions

    class << self
      def parse program, transform_context = {}
        parsed = parser.parse(program)
        ast = transform.apply parsed, transform_context

        Ldpath::Program.new ast.compact, prefixes: transform_context[:prefixes]
      end

      private
      def transform
        Ldpath::Transform.new
      end

      def parser
        @parser ||= Ldpath::Parser.new
      end
    end
    
    attr_reader :mappings, :cache, :loaded, :prefixes
    def initialize mappings, options = {}

      @mappings ||= mappings
      @cache = options[:cache] || RDF::Util::Cache.new
      @prefixes = options[:prefixes] || {}
      @loaded = {}
    end
    
    def loading uri, context
      if uri.to_s =~ /^http/ and !loaded[uri]
        context << load_graph(uri)
      end
    end

    def load_graph uri
      cache[uri] ||= begin
        Ldpath.logger.debug "[#{self.object_id}] Loading #{uri.inspect}"

        reader_types = RDF::Format.reader_types.reject { |t| t.to_s =~ /html/ }.map do |t|
          t.to_s =~ /text\/(?:plain|html)/  ? "#{t};q=0.5" : t
        end

        RDF::Graph.load(uri, headers: { 'Accept' => reader_types.join(", ") }).tap { loaded[uri] = true }
      end
    end

    def evaluate uri, context = nil
      h = {}
      context ||= load_graph(uri.to_s)

      mappings.each do |m|
        h[m.name] ||= []
        h[m.name] += case m.selector
        when Selector
          m.selector.evaluate(self, uri, context).map do |x| 
            next x unless m.field_type
            RDF::Literal.new(x.to_s, datatype: m.field_type).canonicalize.object
          end
        else
          Array(m.selector)
        end
      end

      h.merge(meta)
    end

    def meta
      @meta ||= {}
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
