module Ldpath
  class Selector
    
  end
  
  class SelfSelector < Selector
    def evaluate uris, context
      Array(uris).compact
    end 
  end
  
  class FunctionSelector < Struct.new(:fname, :arguments)
    
  end
  class PropertySelector < Struct.new(:property)
    def evaluate uris, context
      Array(uris).map do |uri|
        context.query([uri, property, nil]).map { |x| x.object }
      end.flatten.compact
    end
  end
  
  class WildcardSelector
    def evaluate uris, context
      Array(uris).map do |uri|
        context.query([uri, nil, nil]).map { |x| x.object }
      end.flatten.compact
    end
  end
  
  class ReversePropertySelector < Struct.new(:property)
    def evaluate uris, context
      Array(uris).map do |uri|
        context.query([nil, property, uri]).map { |x| x.subject }
      end.flatten.compact
    end
  end
  
  class RecursivePathSelector < Struct.new(:property, :repeat)
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
