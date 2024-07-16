# frozen_string_literal: true

module Resources
  module Associations
    def self.included(base)
      base.include(AssociationsDSL)
    end

    module AssociationsDSL
      extend Concern

      included do
        mstore :associations_store, unique: true, attribute: :name
      end

      class_methods do
        def associations(&block)
          DSL.call(self, &block)

          associations_store.keys.each do |name|
            define_method(name) do
              associations_store[name].call(self)
            end
            alias_method Inflector.singularize(name), name
          end
        end
      end
      class DSL < BasicObject
        def self.call(source, &block)
          self.class.new(source, &block).store
        end

        # @api private
        def initialize(source, &block)
          @source = source
          @store = Store.build(attribute: :name, unique: true)
          instance_exec(&block)
        end

        attr_reader :source

        # Establish a one-to-many association
        #
        # @example using relation identifier
        #   has_many :tasks
        #
        # @example setting custom foreign key name
        #   has_many :tasks, foreign_key: :assignee_id
        #
        # @example with a :through option
        #   # this establishes many-to-many association
        #   has_many :tasks, through: :users_tasks
        #
        # @example using a custom view which overrides default one
        #   has_many :posts, view: :published, override: true
        #
        # @example using aliased association with a custom view
        #   has_many :posts, as: :published_posts, view: :published
        #
        # @example using custom target relation
        #   has_many :user_posts, relation: :posts
        #
        # @example using custom target relation and an alias
        #   has_many :user_posts, relation: :posts, as: :published, view: :published
        #
        # @param [Symbol] target The target relation identifier
        # @param [Hash] options A hash with additional options
        #
        # @return [Associations::OneToMany]
        #
        # @see #many_to_many
        #
        # @api public
        def has_many(target, **options)
          if options[:through]
            add(Definitions::HasManyThrough.new(source, target, **options))
          else
            add(Definitions::HasMany.new(source, target, **options))
          end
        end

        # @example with an alias (relation identifier is inferred via pluralization)
        #   belongs_to :user
        #
        def belongs_to(target, **options)
          add(Definitions::BelongsTo.new(source, dataset_name(target), **options))
        end

        # Shortcut for one_to_one which sets alias automatically
        #
        # @example with an alias (relation identifier is inferred via pluralization)
        #   has_one :address
        #
        # @example with an explicit alias and a custom view
        #   has_one :posts, as: :priority_post, view: :prioritized
        def has_one(target, **options)
          if options[:through]
            add(Definitions::HasOneThrough.new(source, target, **options))
          else
            add(Definitions::HasOne.new(source, target, **options))
          end
        end

        private

        # @api private
        def add(association)
          source.associations_store.add(association)
        end

        # @api private
        def dataset_name(name)
          Inflector.pluralize(name).to_sym
        end
      end
    end
  end
end
