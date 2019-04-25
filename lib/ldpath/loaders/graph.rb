class Ldpath::Loaders::Direct
  def initialize(graph:)
    @graph = graph
  end

  def load
    @graph
  end
end
