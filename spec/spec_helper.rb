$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'ldpath'
require 'rdf/reasoner'
require 'webmock/rspec'

require 'byebug' unless ENV['TRAVIS']

RDF::Reasoner.apply(:rdfs)
RDF::Reasoner.apply(:owl)

def webmock_fixture(fixture)
  File.new File.expand_path(File.join("../fixtures", fixture), __FILE__)
end

# returns the file contents
def load_fixture_file(fname)
  File.open(Rails.root.join('spec', 'fixtures', fname)) do |f|
    return f.read
  end
end
