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

    defines :auto_struct
    defines :auto_map
    defines :mappers
    defines :adapter
    defines :dataset_adapter

    auto_map true
    auto_struct false

    defines :dataset
    dataset -> { self }
    mappers -> { [] }
    adapter -> { :default }

    option :context
    option :dataset, default: -> { self.class.dataset.new }
    option :auto_map, default: -> { self.class.auto_map }
    option :auto_struct, default: -> { self.class.auto_struct }
    option :mappers, default: -> { self.class.mappers }
    option :meta, reader: true, default: -> { EMPTY_HASH }

    delegate :project_id, :company_id, :user_id, to: :context
    delegate :to_sql, :pluck, to: :dataset
    delegate :adapter, to: :class
    def foreign_key_values(key)
      pluck(key)
    end

    def new(**new_opts)
      opts =
        if new_opts.empty?
          options
        else
          options.merge(new_opts)
        end

      self.class.new(**opts)
    end

    def to_a
      to_enum.to_a
    end

    def with(new_options)
      new(**options, **new_options)
    end

    def associations
      self.class.associations
    end

    def auto_map?
      auto_map || auto_struct
    end

    def auto_struct?
      auto_struct
    end

    def map_with(*names, **opts)
      super(*names).with(opts)
    end

    def map_to(_klass, **opts)
      with(opts.merge(auto_map: false, auto_struct: true))
    end

    def foreign_key(name)
      attr = associations[name].foreign_key(name)

      if attr
        attr.name
      else
        :"#{Inflector.singularize(name)}_id"
      end
    end

    def to_struct(attributes)
      AutoStruct.new(attributes)
    end

    def each(&block)
      return to_enum unless block_given?

      dataset.to_a.map(&method(:to_struct)).each(&block)
    end

    def call
      Loaded.new(self)
    end

    def name
      self.class.relation_name.to_s.singularize
    end

    def to_graph
      Graph.new(relation: self)
    end

    def join(relation:, join_keys: {}, type: :inner)
      if adapter != relation.adapter
        to_graph.join(relation, join_keys, type)
      else
        with(dataset: dataset.join(dataset: relation.dataset, join_keys:, type:))
      end
    end

    def incompatible_adapter?(*_relations)
      adapter != relation.adapter
    end

    def left_outer_joins(*relations)
      build_join(relations, :left)
    end

    def joins(*args)
      build_join(args, :inner)
    end
    alias inner_joins joins

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

    memoize def options
      self.class.dry_initializer.definitions.values.each_with_object({}) do |item, obj|
        obj[item.target] = instance_variable_get(item.ivar)
      end
    end
  end
end
