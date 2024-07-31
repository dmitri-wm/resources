# frozen_string_literal: true

module Resources
  module Associations
    # DSL module for defining associations in resources
    module Dsl
      extend Concern

      included do
        include Storage
        mstore :associations, attribute: :name, unique: true
        # This creates a unique store for associations, keyed by name
      end

      class_methods do
        # Defines associations for a resource
        #
        # @example
        #   class User
        #     associate do
        #       has_many :posts
        #       belongs_to :company
        #     end
        #   end
        def associate(&block)
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
            end

            # Define a method to access associations
            define_method(:associations) do
              lambda do |name|
                self.class.associations[name].tap do
                  raise ArgumentError, "Unknown association: #{name} for #{inspect}" unless _1
                end.build_association(source: self)
              end
            end
          end
        end
      end

      # Internal DSL class for processing association definitions
      class DSL
        # Executes the DSL block and returns the resulting store
        #
        # @param source [Class] The class defining the associations
        # @yield The block containing association definitions
        # @return [Storage::Store] The store containing the defined associations
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

        # Defines a has_many association
        #
        # @param name [Symbol] The name of the association
        # @param options [Hash] Additional options for the association
        # @example
        #   has_many :posts
        #   has_many :comments, through: :posts, assoc_name: :comments, condition: -> { ... }
        def has_many(name, **options)
          if options[:through]
            add(Definitions::HasManyThrough.new(source:, through: options[:through], name:, **options))
          else
            add(Definitions::HasMany.new(source:, name:, **options))
          end
        end

        # Defines a belongs_to association
        #
        # @param name [Symbol] The name of the association
        # @param options [Hash] Additional options for the association
        # @example
        #   belongs_to :company
        def belongs_to(name, **options)
          if options[:through]
            add(Definitions::HasOneThrough.new(source:, name:, **options))
          else
            add(Definitions::BelongsTo.new(source:, name:, **options))
          end
        end

        # Defines a has_one association
        #
        # @param name [Symbol] The name of the association
        # @param options [Hash] Additional options for the association
        # @example
        #   has_one :profile
        #   has_one :avatar, through: :profile
        def has_one(name, **options)
          if options[:through]
            add(Definitions::HasOneThrough.new(source:, name:, **options))
          else
            add(Definitions::HasOne.new(source:, name:, **options))
          end
        end

        private

        # Adds an association to the store
        #
        # @param association [Object] The association object to add
        def add(association)
          store.add(association)
        end

        # Returns the pluralized name of a dataset
        #
        # @param name [Symbol, String] The name to pluralize
        # @return [Symbol] The pluralized name as a symbol
        def dataset_name(name)
          name.pluralize.to_sym
        end
      end
    end
  end
end
