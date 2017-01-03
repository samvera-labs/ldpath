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

  class << self
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

    def logger=(logger)
      @logger = logger
    end
  end
end
