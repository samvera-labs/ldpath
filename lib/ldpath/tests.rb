module Ldpath
  
  class TestSelector < Selector
    attr_reader :delegate, :test

    def initialize delegate, test
      @delegate = delegate
      @test = test
    end

    def evaluate program, uris, context
      entries = delegate.evaluate program, uris, context
      entries.reject do |uri|
        test.evaluate(program, uri, context).empty?
      end
    end
  end

  class LanguageTest < TestSelector
    attr_reader :lang
    def initialize lang
      @lang = lang
    end

    def evaluate program, uris, context
      Array(uris).map do |uri|
        next unless uri.literal?
        if (lang == "none" && !uri.has_language?) or uri.language == lang 
          uri 
        end
      end.flatten.compact
    end
  end

  class TypeTest < TestSelector
    attr_reader :type
    def initialize type
      @type = type
    end

    def evaluate program, uris, context
      Array(uris).map do |uri|
        next unless uri.literal?
        if uri.has_datatype? and uri.datatype == type
          uri
        end
      end.flatten.compact
    end
  end
end
