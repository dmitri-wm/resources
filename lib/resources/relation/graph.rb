class Graph < Dataset
  extend Dry::Initializer

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
    visitor = NestedRelationVisitor.new
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
    self.class.new(
      **options,
      filters: filters.merge(conditions)
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

class EfficientJoin
  extend Dry::Initializer

  option :left
  option :right
  option :join_keys
  option :filters, default: -> { {} }

  # Executes the join and returns the result as an array
  #
  # @return [Array] The result of the join operation
  def to_a
    left_keys = extract_keys_from_left
    right_data = fetch_right_data(left_keys)
    join_data(left_keys, right_data)
  end

  private

  def extract_keys_from_left
    left.pluck(join_keys.values).distinct.to_a
  end

  def fetch_right_data(left_keys)
    right.where(join_keys.keys.zip(left_keys.flatten).to_h).to_a
  end

  def join_data(left_keys, right_data)
    if left.is_a?(SQL::Dataset)
      join_sql_data(left_keys, right_data)
    elsif left.is_a?(ServiceDatasource)
      join_service_data(left_keys, right_data)
    else
      raise NotImplementedError, "Unsupported left datasource type: #{left.class}"
    end
  end

  def join_sql_data(left_keys, right_data)
    # TODO: Implement SQL join logic
    raise NotImplementedError, 'SQL join not implemented yet'
  end

  def join_service_data(left_keys, right_data)
    # TODO: Implement service datasource join logic
    raise NotImplementedError, 'Service datasource join not implemented yet'
  end
end
