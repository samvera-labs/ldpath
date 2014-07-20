require "ldpath/version"
require 'linkeddata'

module Ldpath
  require 'ldpath/field_mapping'
  require 'ldpath/selectors'
  require 'ldpath/tests'
  require 'ldpath/parser'
  require 'ldpath/transform'
  require 'ldpath/program'
  require 'ldpath/functions'
  
  class << self
    def evaluate program, uri, context
      Ldpath::Program.parse(program).evaluate(uri, context)
    end
  end
end
