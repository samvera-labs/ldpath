module Ldpath
  class Selector
    def evaluate uris, context
      Array(uris).map do |uri|
        evaluate_one uri, context
      end.flatten.compact
    end
  end
  
  class SelfSelector < Selector
    def evaluate_one uri, context
      uri
    end 
  end
  
  class FunctionSelector < Selector
    def initialize fname, arguments
      @fname = fname
      @arguments = arguments
    end

    def evaluate_one uri, context
      # TODO
    end
  end
  
  class PropertySelector < Selector
    attr_reader :property
    def initialize property
      @property = property
    end

    def evaluate_one uri, context
      context.query([uri, property, nil]).map(&:object)
    end
  end
  
  class WildcardSelector < Selector
    def evaluate_one uri, context
      context.query([uri, nil, nil]).map(&:object)
    end
  end
  
  class ReversePropertySelector < Selector
    attr_reader :property
    def initialize property
      @property = property
    end
    
    def evaluate_one uri, context
      context.query([nil, property, uri]).map(&:subject)
    end
  end
  
  class RecursivePathSelector < Selector
    attr_reader :property, :repeat
    def initialize property, repeat
      @property = property
      @repeat = repeat
    end
    
    def evaluate uris, context
      result = []
      input = Array(uris)
      
      Range.new(0,repeat.min,true).each do
        input = property.evaluate input, context
      end
      
      repeat.each_with_index do |i, idx|
        break if input.empty? or idx > 25 # we're probably lost..
        input = property.evaluate input, context
        result |= input
      end
      result.flatten.compact
    end
  end
  
  class PathSelector < Struct.new(:left, :right)
    def evaluate uris, context
      output = left.evaluate(uris, context)
      right.evaluate(output, context)
    end
  end
  
  class UnionSelector < Struct.new(:left, :right)
    def evaluate uris, context
      left.evaluate(uris, context) | right.evaluate(uris, context)
    end
  end

  class IntersectionSelector < Struct.new(:left, :right)    
    def evaluate uris, context
      left.evaluate(uris, context) & right.evaluate(uris, context)
    end
  end

end
