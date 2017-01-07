# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldpath/version'

Gem::Specification.new do |spec|
  spec.name          = "ldpath"
  spec.version       = Ldpath::VERSION
  spec.authors       = ["Chris Beer"]
  spec.email         = ["cabeer@stanford.edu"]
  spec.summary       = "Ruby implementation of LDPath"
  spec.homepage      = "https://github.com/cbeer/ldpath.rb"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "parslet"
  spec.add_dependency "linkeddata", '~> 2.0'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rdf-reasoner"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "rubocop"
end
