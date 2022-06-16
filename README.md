# Ldpath

This is a ruby implementation of [LDPath](http://marmotta.apache.org/ldpath/language.html), a language for selecting values linked data resources.

[![Gem Version](https://badge.fury.io/rb/ldpath.png)](http://badge.fury.io/rb/ldpath)
[![Build Status](https://circleci.com/gh/samvera-labs/ldpath.svg?style=svg)]

## Installation

### Required gem installation

Add this line to your application's Gemfile:

    gem 'ldpath'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ldpath

### Additional gem installations

To support RDF serializations, you will need to either install the [linkeddata gem](https://github.com/ruby-rdf/linkeddata) which installs a large set of RDF serializations or, in order to have a smaller dependency footprint, install gems for only the serializations your plan to use in your app.  The list of serializations are in the [README](https://github.com/ruby-rdf/linkeddata/blob/develop/README.md#features) for the linkeddata gem.

## Usage

```ruby
require 'ldpath'

my_program = <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = dcterms:title :: xsd:string ;
EOF

uri = RDF::URI.new "info:a"

context = RDF::Graph.new << [uri, RDF::Vocab::DC.title, "Some Title"]

program = Ldpath::Program.parse my_program
output = program.evaluate uri, context: context
# => { ... }
```

## Compatibility

* Ruby 2.5 or the latest 2.4 version is recommended.  Later versions may also work.

## Contributing 

If you're working on PR for this project, create a feature branch off of `main`. 

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/master/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.

## Product Owner & Maintenance

LDPath is moving toward being a Core Component of the Samvera community. The documentation for
what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

[elrayle](https://github.com/elrayle)

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)

### Special thanks to...

[Chris Beer](https://github.com/cbeer) for the initial implementation of this gem!
