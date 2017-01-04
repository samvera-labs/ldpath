# rubocop:disable Style/MethodName
module Ldpath
  module Functions
    def concat(uri, context, *args)
      deep_flatten_compact(*args).to_a.join
    end

    def first(uri, context, *args)
      deep_flatten_compact(*args).first
    end

    def last(uri, context, *args)
      deep_flatten_compact(*args).to_a.last
    end

    def count(uri, context, *args)
      deep_flatten_compact(*args).count
    end

    def eq(uri, context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      unless rem.empty?
        raise "Too many arguments to fn:eq"
      end
      a == b
    end

    def ne(uri, context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      unless rem.empty?
        raise "Too many arguments to fn:ne"
      end
      a != b
    end

    def lt(uri, context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      unless rem.empty?
        raise "Too many arguments to fn:lt"
      end
      a < b
    end

    def le(uri, context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      unless rem.empty?
        raise "Too many arguments to fn:le"
      end
      a <= b
    end

    def gt(uri, context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      unless rem.empty?
        raise "Too many arguments to fn:gt"
      end
      a > b
    end

    def ge(uri, context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      unless rem.empty?
        raise "Too many arguments to fn:ge"
      end
      a >= b
    end

    # collections
    def flatten(uri, context, lists)
      return to_enum(:flatten, uri, context, lists) unless block_given?

      deep_flatten_compact(lists).each do |x|
        RDF::List.new(subject: x, graph: context).to_a.each do |i|
          yield i
        end
      end
    end

    def get(uri, context, list, idx)
      idx = idx.respond_to?(:to_i) ? idx.to_i : idx.to_s.to_i

      flatten(uri, context, list).to_a[idx]
    end

    def subList(uri, context, list, idx_start, idx_end = nil)
      arr = flatten(uri, context, list).to_a

      idx_start = idx_start.respond_to?(:to_i) ? idx_start.to_i : idx_start.to_s.to_i
      idx_end &&= idx_end.respond_to?(:to_i) ? idx_end.to_i : idx_end.to_s.to_i

      if idx_end
        arr[(idx_start.to_i..(idx_end - idx_start))]
      else
        arr.drop(idx_start)
      end
    end

    # dates

    def earliest(uri, context, *args)
      deep_flatten_compact(*args).min
    end

    def latest(uri, context, *args)
      deep_flatten_compact(*args).max
    end

    # math

    def min(uri, context, *args)
      deep_flatten_compact(*args).min
    end

    def max(uri, context, *args)
      deep_flatten_compact(*args).max
    end

    def round(uri, context, *args)
      deep_flatten_compact(*args).map do |i|
        i.respond_to? :round ? i.round : i
      end
    end

    def sum(uri, context, *args)
      args.inject(0) { |sum, n| sum + n }
    end

    # text

    def replace(uri, context, str, pattern, replacement)
      regex = Regexp.parse(pattern)
      Array(str).map do |x|
        x.gsub(regex, replacement)
      end
    end

    def strlen(uri, context, str)
      Array(str).map(&:length)
    end

    def wc(uri, context, str)
      Array(str).map { |x| x.split.length }
    end

    def strLeft(uri, context, str, left)
      Array(str).map { |x| x[0..left.to_i] }
    end

    def strRight(uri, context, str, right)
      Array(str).map { |x| x[right.to_i..x.length] }
    end

    def substr(uri, context, str, left, right)
      Array(str).map { |x| x[left.to_i..right.to_i] }
    end

    def strJoin(uri, context, str, sep = "", prefix = "", suffix = "")
      prefix + Array(str).join(sep) + suffix
    end

    def equals(uri, context, str, other)
      Array(str).map { |x| x == other }
    end

    def equalsIgnoreCase(uri, context, str, other)
      Array(str).map { |x| x.downcase == other.downcase }
    end

    def contains(uri, context, str, substr)
      Array(str).map { |x| x.include? substr }
    end

    def startsWith(uri, context, str, suffix)
      Array(str).map { |x| x.start_with? suffix }
    end

    def endsWith(uri, context, str, suffix)
      Array(str).map { |x| x.end_with? suffix }
    end

    def isEmpty(uri, context, str)
      Array(str).map(&:empty?)
    end

    def predicates(uri, context, *args)
      context.query([uri, nil, nil]).map(&:predicate).uniq
    end

    def xpath(uri, context, xpath, node)
      x = Array(xpath).flatten.first
      Array(node).flatten.compact.map do |n|
        Nokogiri::XML(n.to_s).xpath(x.to_s, prefixes.map { |k, v| [k, v.to_s] }).map(&:text)
      end
    end

    private

    def deep_flatten_compact(*args)
      return to_enum(:deep_flatten_compact, *args) unless block_given?

      args.each do |x|
        if x.is_a? Enumerable
          x.each { |y| yield y unless y.nil? }
        else
          yield x unless x.nil?
        end
      end
    end
  end
end
