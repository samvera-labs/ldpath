module Ldpath
  class Result
    include Ldpath::Functions
    attr_reader :program, :uri, :cache, :loaded

    def initialize(program, uri, cache: RDF::Util::Cache.new, context: nil)
      @program = program
      @uri = uri
      @cache = cache
      @loaded = {}
      @context = context
    end

    def loading(uri, context)
      return unless uri.to_s =~ /^http/
      return if loaded[uri.to_s]

      context << load_graph(uri.to_s)
    end

    def load_graph(uri)
      cache[uri] ||= begin
        Ldpath.logger.debug "[#{object_id}] Loading #{uri.inspect}"

        reader_types = RDF::Format.reader_types.reject { |t| t.to_s =~ /html/ }.map do |t|
          t.to_s =~ %r{text/(?:plain|html)} ? "#{t};q=0.5" : t
        end

        RDF::Graph.load(uri, headers: { 'Accept' => reader_types.join(", ") }).tap { loaded[uri] = true }
      end
    end

    def [](key)
      evaluate(mappings.find { |x| x.name == key })
    end

    def to_hash
      h = mappings.each_with_object({}) do |mapping, hash|
        hash[mapping.name] = evaluate(mapping)
      end

      h.merge(meta)
    end

    def func_call(fname, uri, context, *arguments)
      raise "No such function: #{fname}" unless function_method? fname

      public_send(fname, uri, context, *arguments)
    end

    def context
      @context ||= load_graph(uri.to_s)
    end

    def prefixes
      program.prefixes
    end

    def meta
      @meta ||= {}
    end

    private

    def evaluate(mapping)
      case mapping.selector
      when Selector
        mapping.selector.evaluate(self, uri, context).map do |x|
          v = if x.is_a? RDF::Literal
                x.canonicalize.object
              else
                x
              end

          next v unless mapping.field_type
          RDF::Literal.new(v.to_s, datatype: mapping.field_type).canonicalize.object
        end
      when RDF::Literal
        Array(mapping.selector.canonicalize.object)
      else
        Array(mapping.selector)
      end
    end

    def function_method?(function)
      Functions.public_instance_methods(false).include? function.to_sym
    end

    def mappings
      program.mappings
    end
  end
end
