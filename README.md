# Ldpath

This is a ruby implementation of [LDPath](http://marmotta.apache.org/ldpath/language.html), a language for selecting values linked data resources.

## Installation

Add this line to your application's Gemfile:

    gem 'ldpath'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ldpath

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
output = program.evaluate uri, context
# => { ... }
```
 
## Contributing

1. Fork it ( http://github.com/cbeer/ldpath.rb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
