# frozen_string_literal: true

# domain: Change Events

module Resources
  class Relation
    include Storage
    include Associations::Dsl
    include Memoizable
    include Materializable
    extend Forwardable

    extend Initializer
    extend Dry::Core::ClassAttributes
    include Registry

    register into: :relations, by: :name

    EMPTY_HASH = {}.freeze

    # Defines class-level attributes with getter and setter methods.
    # This is used to define configuration options for the relation.
    #
    # @macro [attach] defines
    #   @!attribute [rw] $1
    #   @return [Object] the value of the $1 attribute
    defines :auto_struct, :auto_map, :mappers, :adapter, :dataset

    # Defines class-level accessor for dataset
    # @!attribute [rw] dataset
    adapter -> { :default }
    auto_map true
    auto_struct false
    dataset -> { self }
    mappers -> { [] }

    # Defines instance-level attributes with optional default values.
    # These attributes configure the behavior of each relation instance.
    #
    # @macro [attach] option
    #   @!attribute [rw] $1
    #   @return [Object] the value of the $1 attribute
    option :context
    option :dataset, default: -> { self.class.dataset.new }
    option :auto_map, default: -> { self.class.auto_map }
    option :auto_struct, default: -> { self.class.auto_struct }
    option :mappers, default: -> { self.class.mappers }
    option :meta, reader: true, default: -> { EMPTY_HASH }

    delegate :project_id, :company_id, :user_id, to: :context
    delegate :pluck, to: :dataset
    delegate :adapter, to: :class

    # Returns the values of the specified foreign key.
    #
    # @param key [Symbol] the foreign key
    # @return [Array] the values of the foreign key
    def foreign_key_values(key)
      pluck(key)
    end

    # Creates a new instance of the relation with the given options.
    #
    # @param new_opts [Hash] the new options
    # @return [Relation] the new relation instance
    def new(**new_opts)
      opts =
        if new_opts.empty?
          options
        else
          options.merge(new_opts)
        end

      self.class.new(**opts)
    end

    # Converts the relation to an array.
    #
    # @return [Array] the array representation of the relation
    def to_a
      to_enum.to_a
    end

    # Creates a new relation with the given options.
    #
    # @param new_options [Hash] the new options
    # @return [Relation] the new relation instance
    def with(new_options)
      new(**options, **new_options)
    end

    # Returns the associations of the relation.
    #
    # @return [Associations::Dsl] the associations
    def associations
      self.class.associations
    end

    # Checks if auto mapping is enabled.
    #
    # @return [Boolean] true if auto mapping is enabled, false otherwise
    def auto_map?
      auto_map || auto_struct
    end

    # Checks if auto struct is enabled.
    #
    # @return [Boolean] true if auto struct is enabled, false otherwise
    def auto_struct?
      auto_struct
    end

    # Maps the relation with the given names and options.
    #
    # @param names [Array<Symbol>] the names to map
    # @param opts [Hash] the options
    # @return [Relation] the mapped relation
    def map_with(*names, **opts)
      super(*names).with(opts)
    end

    # Maps the relation to the given class with the given options.
    #
    # @param _klass [Class] the class to map to
    # @param opts [Hash] the options
    # @return [Relation] the mapped relation
    def map_to(_klass, **opts)
      with(opts.merge(auto_map: false, auto_struct: true))
    end

    # Returns the foreign key for the given association name.
    #
    # @param name [Symbol] the association name
    # @return [Symbol] the foreign key
    def foreign_key(name)
      attr = associations[name].foreign_key(name)

      if attr
        attr.name
      else
        :"#{Inflector.singularize(name)}_id"
      end
    end

    # Converts the given attributes to a struct.
    #
    # @param attributes [Hash] the attributes
    # @return [AutoStruct] the struct
    def to_struct(attributes)
      AutoStruct.new(attributes)
    end

    # Iterates over each element in the relation.
    #
    # @yield [Object] the block to execute for each element
    # @return [Enumerator] the enumerator if no block is given
    def each(&block)
      return to_enum unless block_given?

      dataset.to_a.map(&method(:to_struct)).each(&block)
    end

    # Calls the relation and returns a loaded instance.
    #
    # @return [Loaded] the loaded instance
    def call
      Loaded.new(self)
    end

    # Returns the name of the relation.
    #
    # @return [String] the name of the relation
    def name
      self.class.relation_name.to_s.singularize
    end

    # Converts the relation to a graph.
    #
    # @return [Graph] the graph
    def to_graph
      Graph.new(relation: self)
    end

    # Joins the relation with another relation.
    #
    # @param relation [Relation] the relation to join with
    # @param join_keys [Hash] the join keys
    # @param type [Symbol] the join type
    # @return [Relation] the joined relation
    def join(relation:, join_keys: {}, type: :inner)
      if use_graph_join?(relation)
        to_graph.join(relation, join_keys, type)
      else
        with(dataset: dataset.join(dataset: relation.dataset, join_keys:, type:))
      end
    end

    # Checks if a graph join should be used.
    #
    # @param relation [Relation] the relation to check
    # @return [Boolean] true if a graph join should be used, false otherwise
    def use_graph_join?(relation)
      adapter != relation.adapter
    end

    # Performs a left outer join with the given relations.
    #
    # @param relations [Array<Relation>] the relations to join with
    # @return [Relation] the joined relation
    def left_outer_joins(*relations)
      build_join(relations, :left)
    end

    # Performs an inner join with the given arguments.
    #
    # @param args [Array] the arguments
    # @return [Relation] the joined relation
    def joins(*args)
      build_join(args, :inner)
    end
    alias inner_joins joins

    # Builds a join with the given relations and join type.
    #
    # @param relations [Array<Relation>] the relations to join with
    # @param type [Symbol] the join type
    # @return [Relation] the joined relation
    def build_join(relations, type)
      relations.reduce(self) do |rel, arg|
        case arg
        when Symbol
          association = rel.associations[arg]
          raise ArgumentError, "Unknown association: #{arg}" unless association

          association.join(type)
        when Hash
          arg.each do |assoc_name, children|
            association = rel.associations[assoc_name]
            raise ArgumentError, "Unknown association: #{assoc_name}" unless association

            target_relation = association.target
            joined_target = target_relation.joins(children)
            rel = rel.join(relation: joined_target, join_keys: association.join_keys, type:)
          end

          rel
        when Array
          rel.joins(*arg)
        else
          raise ArgumentError, "Unsupported argument type: #{arg.class}"
        end
      end
    end
  end
end
