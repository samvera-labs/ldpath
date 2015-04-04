module Ldpath
  module Functions
    def concat uri, context, *args
      args.flatten.compact.join
    end
    
    def first uri, context, *args
      args.flatten.compact.first
    end
    
    def last uri, context, *args
      args.flatten.compact.last
    end

    def count uri, context, *args
      args.flatten.compact.length
    end
    
    def eq uri, context, *args
      a, b, *rem = args.flatten
      unless rem.empty?
        raise "Too many arguments to fn:eq"
      end
      a == b
    end
    
    def ne uri, context, *args
      a, b, *rem = args.flatten
      unless rem.empty?
        raise "Too many arguments to fn:ne"
      end
      a != b
    end
    
    def lt uri, context, *args
      a, b, *rem = args.flatten
      unless rem.empty?
        raise "Too many arguments to fn:lt"
      end
      a < b
    end
    
    def le uri, context, *args
      a, b, *rem = args.flatten
      unless rem.empty?
        raise "Too many arguments to fn:le"
      end
      a <= b
    end
    
    def gt uri, context, *args
      a, b, *rem = args.flatten
      unless rem.empty?
        raise "Too many arguments to fn:gt"
      end
      a > b
    end
    
    def ge uri, context, *args
      a, b, *rem = args.flatten
      unless rem.empty?
        raise "Too many arguments to fn:ge"
      end
      a >= b
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
      args.flatten.min
    end
    
    def latest uri, context, *args
      args.flatten.max
    end
    
    # math
    
    def min uri, context, *args
      args.flatten.min
    end
    
    def max uri, context, *args
      args.flatten.max
    end
    
    def round uri, context, *args
      args.map do |n| 
        Array(n).map do |i|
          i.respond_to? :round ? i.round : i
        end
      end
    end
    
    def sum uri, context, *args
      args.inject(0) { |sum, n| sum + n }
    end
    
    # text
    
    def replace uri, context, str, pattern, replacement
      regex = Regexp.parse(pattern)
      Array(str).map do |x|
        x.gsub(regex, replacement)
      end
    end
    
    def strlen uri, context, str
      Array(str).map { |x| x.length }
    end
    
    def wc uri, context, str
      Array(str).map { |x| x.split.length }
    end
    
    def strLeft uri, context, str, left
      Array(str).map { |x| x[0..left.to_i] }
    end
    
    def strRight uri, context, str, right
      Array(str).map { |x| x[right.to_i..x.length] }
    end
    
    def substr uri, context, str, left, right
      Array(str).map { |x| x[left.to_i..right.to_i] }
    end
    
    def strJoin uri, context, str, sep = "", prefix = "", suffix = ""
      prefix + Array(str).join(sep) + suffix
    end
    
    def equals uri, context, str, other
      Array(str).map { |x| x == other }
    end
    
    def equalsIgnoreCase uri, context, str, other
      Array(str).map { |x| x.downcase == other.downcase }
    end
    
    def contains uri, context, str, substr
      Array(str).map { |x| x.include? substr }
    end
    
    def startsWith uri, context, str, suffix
      Array(str).map { |x| x.start_with? suffix }
    end
    
    def endsWith uri, context, str, suffix
      Array(str).map { |x| x.end_with? suffix }
    end
    
    def isEmpty uri, context, str
      Array(str).map(&:empty?)
    end

    def predicates uri, context, *args
      context.query([uri, nil, nil]).map(&:predicate).uniq
    end

    def xpath uri, context, xpath, node
      x = Array(xpath).flatten.first
      Array(node).flatten.compact.map do |n|
        Nokogiri::XML(n).xpath(x, prefixes.map { |k,v| [k, v.to_s] }).map(&:text)
      end
    end
  
  end
end
