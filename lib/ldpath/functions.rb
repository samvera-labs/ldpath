module Ldpath
  class Functions
    def concat uri, context, *args
      args.join
    end
    
    def first uri, context, *args
      args.compact.first
    end
    
    def last uri, context, *args
      args.compact.last
    end
    
    def eq uri, context, *args
      
    end
    
    def ne uri, context, *args
      
    end
    
    def lt uri, context, *args
      
    end
    
    def le uri, context, *args
      
    end
    
    def gt uri, context, *args
      
    end
    
    def ge uri, context, *args
      
    end
    
    # collections
    def flatten uri, context, *args
      
    end
    
    def get uri, context, *args
    end
    
    def subList uri, context, *args
      
    end
    
    # dates
    
    def earliest uri, context, *args
      args.min
    end
    
    def latest uri, context, *args
      args.max
    end
    
    # math
    
    def min uri, context, *args
      args.min
    end
    
    def max uri, context, *args
      args.max
    end
    
    def round uri, context, *args
      args.map { |n| n.respond_to? :round ? n.round : n }
    end
    
    def sum uri, context, *args
      args.inject(0) { |sum, n| sum + n }
    end
    
    # text
    
    def replace uri, context, str, pattern, replacement
      str.gsub(Regexp.parse(pattern), replacement)
    end
    
    def strlen uri, context, str
      str.length
    end
    
    def wc uri, context, str
      str.split.length
    end
    
    def strLeft uri, context, str, left
      str[0..left.to_i]
    end
    
    def strRight uri, context, str, right
      str[right.to_i..str.length]
      
    end
    
    def substr uri, context, str, left, right
      str[left.to_i..right.to_i]
    end
    
    def strJoin uri, context, str, sep = "", prefix = "", suffix = ""
      prefix + str.join(sep) + suffix
    end
    
    def equals uri, context, *args
      raise "" unless args.length == 2
      
      args[0] == args[1]
    end
    
    def equalsIgnoreCase uri, context, *args
      raise "" unless args.length == 2
      
      args[0].downcase == args[1].downcase
    end
    
    def contains uri, context, *args
      raise "" unless args.length == 2
      
      args[0].include? args[1]
    end
    
    def startsWith uri, context, *args
      raise "" unless args.length == 2
      
      args[0].start_with? args[1]
    end
    
    def endsWith uri, context, *args
      raise "" unless args.length == 2
      
      args[0].end_with? args[1]
    end
    
    def isEmpty uri, context, *args
      raise "" unless args.length == 1
      
      args[0].empty?
    end
  
  end
end
