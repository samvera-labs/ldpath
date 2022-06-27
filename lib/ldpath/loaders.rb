# frozen_string_literal: true

module Ldpath
  module Loaders
    autoload(:Direct, 'ldpath/loaders/direct')
    autoload(:Graph, 'ldpath/loaders/graph')
    autoload(:LinkedDataFragment, 'ldpath/loaders/linked_data_fragment')
  end
end
