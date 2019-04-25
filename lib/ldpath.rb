require "ldpath/version"
require 'linkeddata'
require 'logger'

module Ldpath
  require 'ldpath/field_mapping'
  require 'ldpath/selectors'
  require 'ldpath/tests'
  require 'ldpath/parser'
  require 'ldpath/transform'
  require 'ldpath/functions'
  require 'ldpath/program'
  require 'ldpath/result'
  require 'ldpath/loaders'

  class << self
    attr_writer :logger

    def evaluate(program, uri, context)
      Ldpath::Program.parse(program).evaluate(uri, context)
    end

    def logger
      @logger ||= begin
        if defined? Rails
          Rails.logger
        else
          Logger.new(STDERR)
        end
      end
    end
  end
end
