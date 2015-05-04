module Ldpath
  class Selector
    def evaluate(program, uris, context)
      Array(uris).map do |uri|
        loading program, uri, context
        evaluate_one uri, context
      end.flatten.compact
    end

    def loading(program, uri, context)
      program.loading uri, context
    end
  end

  class SelfSelector < Selector
    def evaluate_one(uri, context)
      uri
    end
  end

  class FunctionSelector < Selector
    attr_reader :fname, :arguments

    def initialize(fname, arguments = [])
      @fname = fname
      @arguments = Array(arguments)
    end

    def evaluate(program, uris, context)
      Array(uris).map do |uri|
        loading program, uri, context
        args = arguments.map do |i|
          case i
          when Selector
            i.evaluate(program, uri, context)
          else
            i
          end
        end
        program.func_call fname, uri, context, *args
      end.flatten.compact
    end
  end

  class PropertySelector < Selector
    attr_reader :property
    def initialize(property)
      @property = property
    end

    def evaluate_one(uri, context)
      context.query([uri, property, nil]).map(&:object)
    end
  end

  class LoosePropertySelector < Selector
    attr_reader :property
    def initialize(property)
      @property = property
    end

    def evaluate_one(uri, context)
      return PropertySelector.new(property).evaluate_one(uri_context) unless defined? RDF::Reasoner

      context.query([uri, nil, nil]).select do |result|
        result.predicate.entail(:subPropertyOf).include? property
      end.map(&:object)
    end
  end

  class WildcardSelector < Selector
    def evaluate_one(uri, context)
      context.query([uri, nil, nil]).map(&:object)
    end
  end

  class ReversePropertySelector < Selector
    attr_reader :property
    def initialize(property)
      @property = property
    end

    def evaluate_one(uri, context)
      context.query([nil, property, uri]).map(&:subject)
    end
  end

  class RecursivePathSelector < Selector
    attr_reader :property, :repeat
    def initialize(property, repeat)
      @property = property
      @repeat = repeat
    end

    def evaluate(program, uris, context)
      result = []
      input = Array(uris)

      Range.new(0, repeat.min, true).each do
        input = property.evaluate program, input, context
      end

      repeat.each_with_index do |i, idx|
        break if input.empty? || idx > 25 # we're probably lost..
        input = property.evaluate program, input, context
        result |= input
      end
      result.flatten.compact
    end
  end

  class CompoundSelector < Selector
    attr_reader :left, :right
    def initialize(left, right)
      @left = left
      @right = right
    end
  end

  class PathSelector < CompoundSelector
    def evaluate(program, uris, context)
      output = left.evaluate(program, uris, context)
      right.evaluate(program, output, context)
    end
  end

  class UnionSelector < CompoundSelector
    def evaluate(program, uris, context)
      left.evaluate(program, uris, context) | right.evaluate(program, uris, context)
    end
  end

  class IntersectionSelector < CompoundSelector
    def evaluate(program, uris, context)
      left.evaluate(program, uris, context) & right.evaluate(program, uris, context)
    end
  end

  class TapSelector < Selector
    attr_reader :identifier, :tap
    def initialize(identifier, tap)
      @identifier = identifier
      @tap = tap
    end

    def evaluate(program, uris, context)
      program.meta[identifier] = tap.evaluate(program, uris, context).map { |x| RDF::Literal.new(x.to_s).canonicalize.object }

      Array(uris).map do |uri|
        loading program, uri, context
        evaluate_one uri, context
      end.flatten.compact
    end

    def evaluate_one(uri, context)
      uri
    end
  end
end
