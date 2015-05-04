$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ldpath'

require 'rdf/reasoner'

RDF::Reasoner.apply(:rdfs)
RDF::Reasoner.apply(:owl)
