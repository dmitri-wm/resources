class Graph
  extend Initializer

  # @!attribute [r] relation
  option :relation
  # @!attribute [r] nodes
  option :nodes, default: -> { [] }
  # @!attribute [r] join_keys
  option :join_keys, default: -> { {} }
  # @!attribute [r] filters
  option :filters, default: -> { {} }

  # Joins a relation to the graph
  #
  # @param relation [Symbol, Object] The relation to join
  # @param join_keys [Hash] The keys to use for joining
  # @return [Graph] A new Graph instance with the joined relation
  def join(relation, join_keys = {})
    new_node = self.class.new(relation: relation, join_keys: join_keys)

    self.class.new(
      **options,
      nodes: nodes + [new_node]
    )
  end

  # Performs multiple joins on the graph
  #
  # @param args [Array<Symbol, Hash>] The relations to join
  # @param type [Symbol] The type of join to perform
  # @return [Graph] A new Graph instance with the joined relations
  # @raise [ArgumentError] If an unsupported argument type is provided
  def joins(*args, type: :inner)
    visitor = JoinRelationsVisitor.new
    args.reduce(self) do |result, relation|
      visitor.visit(result, relation, type)
    end
  end

  def join_relation(relation, nested_relations, type)
    if nested_relations.is_a?(Hash) && nested_relations.key?(:join_keys)
      join_keys = nested_relations.delete(:join_keys)
      join(relation: relation, join_keys: join_keys, type: type)
    else
      join(relation: relation, type: type)
    end
  end

  # Applies a where condition to the graph
  #
  # @param conditions [Hash] The conditions to apply
  # @return [Graph] A new Graph instance with the applied conditions
  def where(conditions)
    visitor = FilterRelationsVisitor.new
    new_filters = filters.dup
    visitor.visit(self, conditions)
    self.class.new(
      **options,
      filters: new_filters
    )
  end

  # Executes the graph query
  #
  # @return [Object] The result of the graph query
  def call
    join_nested(relation)
  end

  private

  def join_nested(current_relation)
    nodes.reduce(current_relation) do |result, node|
      joined = efficient_join(result, node)
      node.nodes.empty? ? joined : node.join_nested(joined)
    end
  end

  def efficient_join(left, right)
    EfficientJoin.new(left, right, join_keys: right.join_keys, filters: filters)
  end
end
