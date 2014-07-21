module Ldpath
  
  class TestSelector < Selector
    attr_reader :delegate, :test

    def initialize delegate, test
      @delegate = delegate
      @test = test
    end

    def evaluate program, uris, context
      entries = delegate.evaluate program, uris, context
      entries.select do |uri|
        Array(test.evaluate(program, uri, context)).any? do |x|
          x
        end
      end
    end
  end

  class LanguageTest < TestSelector
    attr_reader :lang
    def initialize lang
      @lang = lang
    end

    def evaluate program, uri, context
      return unless uri.literal?
      if (lang == "none" && !uri.has_language?) or uri.language == lang 
        uri 
      end
    end
  end

  class TypeTest < TestSelector
    attr_reader :type
    def initialize type
      @type = type
    end

    def evaluate program, uri, context
      return unless uri.literal?
      if uri.has_datatype? and uri.datatype == type
        uri
      end
    end
  end
  
  class NotTest < TestSelector
    attr_reader :delegate
    
    def initialize delegate
      @delegate = delegate
    end
    
    def evaluate program, uri, context
      !delegate.evaluate(program, uris, context).any? { |x| x }
    end
  end

  class OrTest < TestSelector
    attr_reader :left, :right
    
    def initialize left, right
      @left = left
      @right = right
    end
    
    def evaluate program, uri, context
      left.evaluate(program, uri, context).any? || right.evaluate(program, uri, context).any?
    end
  end

  class AndTest < TestSelector    

    attr_reader :left, :right
    
    def initialize left, right
      @left = left
      @right = right
    end

    def evaluate program, uri, context
      left.evaluate(program, uri, context).compact.any? &&
         right.evaluate(program, uri, context).compact.any?
    end
  end
end
