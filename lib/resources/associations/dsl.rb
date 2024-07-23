# frozen_string_literal: true

module Resources
  module Associations
    module Dsl
      extend Concern

      included do
        include Storage
        mstore :associations, attribute: :name, unique: true
        # This creates a unique store for associations, keyed by name
      end

      class_methods do
        def associate(&block)
          # Example usage:
          # class User
          #   associate do
          #     has_many :posts
          #     belongs_to :company
          #   end
          # end
          DSL.call(self, &block).then do |store|
            store.each do |name, definition|
              associations.add(definition)

              define_method(name) do
                associations[name].call
              end
              alias_method name.to_s.pluralize, name
              # This creates methods like:
              # user.posts and user.post
              # user.company and user.companies (even though it's singular)
              define_method(:associations) do
                ->(name) { self.class.associations[name].build_association(source: self) }
              end
            end
          end
        end
      end

      class DSL
        def self.call(source, &block)
          new(source, &block).store
        end

        # @api private
        def initialize(source, &block)
          @source = source
          @store = Storage::Store.build(attribute: :name, unique: true)
          instance_exec(&block) if block_given?
        end

        attr_reader :source, :store

        def has_many(name, **options)
          # Example: has_many :posts
          # Example: has_many :comments, through: :posts, assoc_name: :comments, joinable:  true | false | array_to_sql | array, condition: -> { ... }
          if options[:through]
            add(Definitions::HasManyThrough.new(source:, through: options[:through], name:, **options))
          else
            add(Definitions::HasMany.new(source:, name:, **options))
          end
        end

        def belongs_to(name, **options)
          # Example: belongs_to :company
          if options[:through]
            add(Definitions::HasOneThrough.new(source:, name:, **options))
          else
            add(Definitions::BelongsTo.new(source:, name:, **options))
          end
        end

        def has_one(name, **options)
          # Example: has_one :profile
          # Example: has_one :avatar, through: :profile
          if options[:through]
            add(Definitions::HasOneThrough.new(source:, name:, **options))
          else
            add(Definitions::HasOne.new(source:, name:, **options))
          end
        end

        private

        def add(association)
          store.add(association)
        end

        def dataset_name(name)
          name.pluralize.to_sym
        end
      end
    end
  end
end
