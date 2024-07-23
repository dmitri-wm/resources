class Graph < Dataset
  option :relation_name
  option :datasource
  option :join_keys, default: -> { {} }
  option :nodes, default: -> { [] }
  option :filters, default: -> { {} }

  def join(relation, join_keys = {})
    new_node = self.class.new(
      relation_name: relation,
      datasource: associations[relation].datasource,
      join_keys: join_keys
    )
    self.class.new(
      relation_name: relation_name,
      datasource: datasource,
      join_keys: self.join_keys,
      nodes: nodes + [new_node],
      filters: filters
    )
  end

  def joins(relations)
    case relations
    when Symbol
      join(relations)
    when Hash
      relations.reduce(self) do |result, (relation, nested_relations)|
        new_node = result.join(relation)
        if nested_relations
          new_node.nodes.last.joins(nested_relations)
        else
          new_node
        end
      end
    else
      raise ArgumentError, "Unsupported argument type for joins: #{relations.class}"
    end
  end

  def node(name, &block)
    new_nodes = update_nodes(name, &block)
    self.class.new(
      relation_name: relation_name,
      datasource: datasource,
      join_keys: join_keys,
      nodes: new_nodes
    )
  end

  def where(conditions)
    self.class.new(
      relation_name: relation_name,
      datasource: datasource,
      join_keys: join_keys,
      nodes: nodes,
      filters: filters.merge(conditions)
    )
  end

  def call
    join_nested(datasource)
  end

  private

  def join_nested(current_datasource)
    nodes.reduce(current_datasource) do |result, node|
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
    # this logic should be handled in dataset?
    # when left is sql we need right data convert to sql
    # when left is service_datasource we need right data convert array of hashes
  end
end
