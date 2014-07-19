module Ldpath
  
  class TestSelector < Struct.new(:delegate, :test)
    def evaluate uris, context
      entries = delegate.evaluate uris, context
      entries.reject do |uri|
        test.evaluate(uri, context).empty?
      end
    end
  end

  class LanguageTest < Struct.new(:lang)
    def evaluate uris, context
      Array(uris).map do |uri|
        next unless uri.literal?
        if (lang == "none" && !uri.has_language?) or uri.language == lang 
          uri 
        end
      end.flatten.compact
    end
  end
end
