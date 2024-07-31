# frozen_string_literal: true

module Resources
  class Relation
    class Graph
      extend Initializer
      extend Forwardable
      include AutoCurry
      include Dry::Equalizer(:relation, :meta, :filters, :nodes)

      # @!method initialize(relation:, nodes: [], meta: {})
      option :relation
      # @!attribute [r] nodes
      option :nodes, default: -> { [].freeze }
      # @!attribute [r] filters
      option :filters, default: -> { [].freeze }
      # @!attribute [r] meta
      option :meta, default: -> { EMPTY_HASH.freeze }

      # @!attribute [r]
      option :after_execute, default: -> { {} }

      forward :paginate, :order, to: :relation

      # Joins a relation to the graph
      #
      # @param relation [Symbol, Object] The relation to join
      # @param join_keys [Hash] The keys to use for joining
      # @param type [Symbol] The type of join (default: :inner)
      # @param name [String, nil] The name of the relation (default: nil)
      # @return [Graph] A new Graph instance with the joined relation
      # @example
      #   graph.join(:users, { id: :user_id }, type: :left, name: 'user_join')
      def join(relation, join_keys = {}, type: :inner, name: nil)
        build_node[{ relation:, meta: { join_type: type, join_keys:, name: name || relation.relation_name } }].then(&add_to_nodes)
      end

      # Performs a left outer join with the given relations.
      #
      # @param args [Array<Relation>] Leaf relations to join with
      # @param kwargs [Hash<Relation>] Node relations (leaf with children) to join with
      # @return [Relation] The joined relation
      # @example
      #   graph.left_outer_join(users, posts: comments)
      def left_outer_join(*args, **kwargs)
        joins_on_schema(args, kwargs, :left)
      end

      def join_by_type(type, *args, **kwargs)
        joins_on_schema(args, kwargs, type)
      end

      # Performs an inner join with the given arguments.
      #
      # @param args [Array<Relation>] Leaf relations to join with
      # @param kwargs [Hash<Relation>] Node relations (leaf with children) to join with
      # @return [Relation] The joined relation
      # @example
      #   graph.joins(users, posts: comments)
      def joins(*args, **kwargs)
        joins_on_schema(args, kwargs, :inner)
      end
      alias inner_joins joins

      # Retrieves a node from the graph based on the given path and applies a block to it.
      #
      # @param path [Array<Symbol>] The path to the node
      # @param block [Proc] The block to apply to the node
      # @return [Graph] The updated graph
      # @example
      #   graph.node(:users, :posts) { |node| node.update(meta: { active: true }) }
      def node(*path, &block)
        dig(path).then(&block).then(&method(:update_node))
      end

      # Digs into the graph to retrieve a node based on the given path.
      #
      # @param path [Array<Symbol>] The path to the node
      # @return [Graph] The retrieved node
      # @example
      #   graph.dig(:users, :posts)
      def dig(*path)
        path.reduce(self, :fetch_node)
      end

      def key_map
        meta[:join_keys].to_a.flatten(1)
      end

      def target_key
        key_map.last
      end

      def source_key
        key_map.first
      end

      # Applies a where condition to the graph
      #
      # @param conditions [Hash] The conditions to apply
      # @return [Graph] A new Graph instance with the applied conditions
      # @example
      #   graph.where(active: true)
      #   graph.where(active: true).where(archived: false)
      #   graph.where(active: true, users: { name: 'Jane', posts: { title: 'Hello' } })
      def where(conditions)
        Visitors::GraphPathVisitor.visit(self, conditions) do |node, filters|
          node.with(filters: node.filters + [filters])
        end
      end

      def distinct(*args)
        add_to_post_execute(:distinct, *args)
      end

      def select(*args)
        add_to_post_execute(:select, *args)
      end

      def add_to_post_execute(key, *args)
        with(after_execute: { **after_execute, **{ key => [*after_execute[key] || [], *args] } })
      end

      def data_service?
        relation.adapter == :data_service
      end

      def prepare
        Visitors::GraphVisitor.visit(self) do |parent|
          self.then(&apply_foreign_keys[parent])
              .then(&apply_filters[filters])
              .then(&preload_foreign_keys)
        end
      end

      # @return [Graph] The updated graph
      curry def apply_foreign_keys(left, node)
        return node unless left.present?
        return node unless (pk_filter_values = left.relation.meta.dig(:pf_keys, node.target_key))

        node.where(node.target_key => pk_filter_values)
      end

      # @return [Graph] The updated graph
      curry def apply_filters(filters, node)
        return node unless filters.any?(&:present?)

        node.with(relation: filters.reduce(relation, :where), filters: [])
      end

      # @return [Array<Symbol>] The association names to fetch for foreign key extraction
      def fetch_assoc_names_for_fk_extraction(node)
        node.nodes.then do |child_nodes|
          child_nodes = child_nodes.select(&:data_service?) unless node.data_service?
          child_nodes
        end.map(&:assoc_name)
      end

      curry def preload_foreign_keys(node)
        return node unless (assoc_names = fetch_assoc_names_for_fk_extraction(node).presence)

        node.with(relation: node.relation.preload_foreign_keys(assoc_names))
      end

      def root?
        meta[:root]
      end

      def collapsed?
        meta[:collapsed]
      end

      def post_process(result)
        collapse_result(result)
          .then(&method(:root_callbacks))
      end

      def root_callbacks(result)
        return result unless root?

        after_execute.reduce(result) do |data, (method, args)|
          data.send(method, *args)
        end
      end

      def collapse_result(result)
        return result unless collapsed?

        result.filter_map do |row|
          target = row[nodes.first.meta[:name]]

          next unless target

          { **target, join_id => row[target_key] }
        end
      end

      # Executes the graph query
      #
      # @return [Object] The result of the graph query
      # @example
      #   graph.call
      def call
        prepare.execute.then do |result|
          post_process(result)
        end
      end
      alias to_a call

      # Converts the graph to an abstract syntax tree (AST)
      #
      # @return [Array] The AST representation of the graph
      # @example
      #   graph.to_ast
      def to_ast
        [ast_id, self]
      end

      def ast_id
        assoc_name
      end

      def assoc_name
        meta[:name]
      end

      # Joins relations based on the schema
      #
      # @param leafs [Array<Relation>] Leaf relations to join with
      # @param leaf_nodes [Hash<Relation>] Node relations (leaf with children) to join with
      # @param type [Symbol] The type of join
      # @return [Graph] The updated graph
      # @example
      #   graph.joins_on_schema([users], { posts: comments }, :inner)
      def joins_on_schema(leafs, leaf_nodes, type)
        [*leafs, *leaf_nodes.keys]
          .map(&key_to_node[type]) # build nodes from leafs and leaf_node roots
          .map(&join_leaf_nodes_children[leaf_nodes, type]) # join leaf nodes children
          .then(&add_to_nodes)
      end

      # Joins leaf nodes based on the schema
      #
      # @param leaf_nodes [Hash<Relation>] Node relations (leaf with children) to join with
      # @param type [Symbol] The type of join
      # @param node [Graph] The node to join
      # @return [Graph] The updated node
      # @example
      #   graph.join_leaf_nodes_children({ posts: comments }, :inner, node)
      curry def join_leaf_nodes_children(leaf_nodes, type, node)
        leaf_nodes[node.meta[:name]].then do |schema|
          return node if schema.nil?

          schema.is_a?(Hash) ? node.joins_on_schema([], schema, type) : node.joins_on_schema(Array(schema), {}, type)
        end
      end

      # Converts a key to a node based on the join type
      #
      # @param join_type [Symbol] The type of join
      # @param key [Symbol] The key to convert
      # @return [Graph] The converted node
      # @example
      #   graph.key_to_node(:inner, :users)
      curry def key_to_node(join_type, key)
        fetch_node(key) || generate_node(join_type, key)
      end

      def generate_node(join_type, key)
        association = fetch_association(key)

        if association.through
          generate_nested_node(association, join_type)
        else
          generate_single_node(association, join_type)
        end
      end

      def generate_nested_node(association, join_type)
        to_nested_node_params(association, join_type).then do |params|
          build_node(params).then do |node|
            node.joins_on_schema(unpack_through_schema(association).values, {}, join_type)
          end
        end
      end

      #  class Author
      #  has_many :posts
      #  has_many :comments, through: :posts, assoc_name: :comments
      #  has_many :likes, through: :comments, assoc_name: :likes
      #  has_many :users_who_like, through: :likes
      #  has_many :parents, through: users_who_like
      #
      #  class User
      #  has_many :profiles
      #  has_many :parents, through: :profiles
      #
      #  { comments: { likes: { users_who_like: { :parents } } } } }
      #
      def unpack_through_schema(association, parent_schema = {})
        if association.through
          parent_schema.merge({ association.through_assoc_name => unpack_through_schema(association.target_association) })
        else
          association.name
        end
      end

      def generate_single_node(association, join_type)
        to_node_params(association, join_type).then(&build_node)
      end

      def to_nested_node_params(association, join_type)
        {
          relation: association.through_relation,
          meta: {
            collapsed: true,
            join_keys: association.through_association.join_keys,
            result: association.result,
            name: association.name,
            join_type: join_type
          }
        }
      end

      def with_collapsed_id(join_keys)
        return join_keys unless meta[:collapsed]

        ((sk, *)) = *join_keys

        { sk => join_id }
      end

      def join_id
        :join_id
      end

      # Converts a key to node parameters based on the join type
      # @param association [Association] The association to convert into node parameters
      # @param join_type [Symbol] The type of join
      # @return [Hash] The node parameters
      # @example
      #   graph.to_node_params(:users, :inner)
      def to_node_params(association, join_type)
        {
          relation: association.target,
          meta: {
            join_keys: association.join_keys,
            result: association.result,
            name: association.name,
            join_type: join_type
          }
        }
      end

      # Fetches an association based on the key
      #
      # @param key [Symbol] The key to fetch the association for
      # @return [Object] The fetched association
      # @raise [RuntimeError] If the association is not found
      # @example
      #   graph.fetch_association(:users)
      def fetch_association(key)
        associations[key].tap do |association|
          raise "Association #{key} not found" unless association
        end
      end

      def associations
        relation.associations
      end

      def nodes_map
        nodes.then(&to_map)
      end

      curry def to_map(collection)
        collection.index_by(&:ast_id)
      end

      # Fetches a node based on the key
      #
      # @param key [Symbol] The key to fetch the node for
      # @return [Graph, nil] The fetched node or nil if not found
      # @example
      #   graph.fetch_node(:users)
      def fetch_node(key)
        nodes_map[key]
      end

      # Fetches a node based on the key, raising an error if not found
      #
      # @param key [Symbol] The key to fetch the node for
      # @return [Graph] The fetched node
      # @raise [RuntimeError] If the node is not found
      # @example
      #   graph.fetch_node!(:users)
      def fetch_node!(key)
        fetch_node(key) || raise("Node #{key} not found")
      end

      # Builds a new node with the given parameters
      #
      # @param params [Hash] The parameters for the new node
      # @return [Graph] The new node
      # @example
      #   graph.build_node(relation: users, meta: { join_type: :inner })
      curry def build_node(params)
        self.class.new(**params)
      end

      # Updates a node in the graph
      #
      # @param node [Graph] The node to update
      # @return [Graph] The updated graph
      # @example
      #   graph.update_node(node)
      def update_node(node)
        with_nodes(node)
      end

      # Adds a node to the graph
      #
      # @param node [Graph] The node to add
      # @return [Graph] The updated graph
      # @example
      #   graph.add_to_nodes(node)
      curry def add_to_nodes(node)
        with_nodes(node)
      end

      # Visualizes the graph
      #
      # @param indent [Integer] The indentation level (used for recursive calls)
      # @example
      #   graph.visualize
      def visualize(indent = 0)
        tab = ->(overload = indent) { ' ' * overload }
        line = ->(text) { puts [tab.call, text, "\n"].join }
        is_parent = indent.zero?
        is_child = !is_parent

        if is_child
          pointer_tab = tab.call(indent)
          puts %W[#{pointer_tab}| #{pointer_tab}|].join("\n")
        end

        [
          "Graph: #{relation.relation_name}",
          "Meta: #{meta.inspect}",
          "Filters: #{filters.inspect}"
        ].each_with_index do |text, index|
          if is_child
            line.call("#{is_child && index.zero? ? "|---" : "|   "} #{text}")
          else
            line.call(text)
          end
        end

        nodes.each do |node|
          node.visualize(indent + 5)
        end
      end

      # Updates the graph with new nodes
      #
      # @param new_nodes [Array<Graph>] The new nodes to add
      # @return [Graph] The updated graph
      # @example
      #   graph.with_nodes(new_node)
      def with_nodes(*new_nodes)
        with(nodes: combine_nodes(nodes, new_nodes))
      end

      def combine_nodes(left, right)
        { **left.then(&to_map), **right.flatten.then(&to_map) }.values
      end

      def execute
        case relation.adapter
        when :active_record
          active_record_joins
        when :data_service
          data_service_joins
        else
          raise "Unsupported root relation type: #{filtered_graph.class}"
        end
      end

      private

      def active_record_joins
        nodes.reduce(relation, &join_node)
      end

      curry def join_node(result, node)
        result.join!(
          relation: node.relation,
          join_keys: node.meta[:join_keys],
          type: node.meta[:join_type],
          name: name
        )
      end

      def data_service_joins
        nodes.reduce(relation, &join_data)
      end

      curry def join_data(result, node)
        node.call.then do |relation|
          result.join!(
            relation: relation,
            join_keys: with_collapsed_id(node.meta[:join_keys]),
            type: node.meta[:join_type],
            name: node.meta[:name]
          )
        end
      end
    end
  end
end
