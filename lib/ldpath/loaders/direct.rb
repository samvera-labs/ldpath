# frozen_string_literal: true

module Ldpath
  module Loaders
    class Direct
      def load(uri)
        Ldpath.logger.debug "Loading #{uri.inspect}"

        reader_types = RDF::Format.reader_types.reject { |t| t.to_s =~ /html/ }.map do |t|
          %r{text/(?:plain|html)}.match?(t.to_s) ? "#{t};q=0.5" : t
        end

        RDF::Graph.load(uri, headers: { 'Accept' => reader_types.join(", ") })
      end
    end
  end
end
