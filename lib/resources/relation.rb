# frozen_string_literal: true

# domain: Change Events

module Resources
  class Relation
    extend ClassInterface

    extend Dry::Initializer
    extend Dry::Core::ClassAttributes

    include Storage
    include Memoizable
    include Associations
    include Forwardable
    include Pipeline

    EMPTY_HASH = {}.freeze

    defines :auto_struct
    defines :auto_map
    defines :mappers

    auto_map true
    auto_struct false

    forward :select, :where, :order, :limit, :offset, :paginate, to: :dataset

    option :context
    option :auto_map, default: -> { self.class.auto_map }
    option :auto_struct, default: -> { self.class.auto_struct }
    option :mappers, [Types::Service], default: -> { self.class.mappers }
    option :meta, reader: true, default: -> { EMPTY_HASH }

    def_delegators :context, :project_id, :company_id, :user_id

    def new(dataset, **new_opts)
      opts =
        if new_opts.empty?
          options
        else
          options.merge(new_opts)
        end

      self.class.new(dataset, **opts)
    end

    def to_a
      to_enum.to_a
    end

    def curried?
      false
    end

    def graph?
      false
    end

    def with(opts)
      new_options =
        if opts.key?(:meta)
          opts.merge(meta: meta.merge(opts[:meta]))
        else
          opts
        end

      new(dataset, **options, **new_options)
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

    def mapper
      mappers[to_ast]
    end

    def map_with(*names, **opts)
      super(*names).with(opts)
    end

    def map_to(klass, **opts)
      with(opts.merge(auto_map: false, auto_struct: true, meta: { mapper: klass }))
    end

    def foreign_key(name)
      attr = associations[name].foreign_key(name)

      if attr
        attr.name
      else
        :"#{Inflector.singularize(name)}_id"
      end
    end

    memoize :auto_map?, :auto_struct?, :foreign_key, :combine, :node

    def call
      Loaded.new(self)
    end
  end
end
