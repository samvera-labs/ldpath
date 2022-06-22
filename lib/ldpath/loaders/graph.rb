# frozen_string_literal: true

module Ldpath
  module Loaders
    class Graph
      def initialize(graph:)
        @graph = graph
      end

      def load(_uri)
        @graph
      end
    end
  end
end
