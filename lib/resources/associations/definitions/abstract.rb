# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      # Abstract base class for association definitions
      # This class provides the foundation for all association types (has_many, belongs_to, etc.)
      #
      # @example Defining a custom association type
      #   class CustomAssociation < Abstract
      #     result :many
      #
      #     def initialize(**opts)
      #       super(**opts, custom_option: true)
      #     end
      #   end
      class Abstract
        extend Dry::Initializer
        extend Dry::Core::ClassAttributes

        defines :result

        # The class that defines the association
        # @example
        #   option :source, User
        option :source

        # The name of the relation (optional)
        # @example
        #   option :relation_name, :posts
        option :relation_name, Types::Symbol, optional: true

        # The name of the association
        # @example
        #   option :name, :author
        option :name, Types::Symbol

        # The result type of the association (:one or :many)
        # @example
        #   option :result, :many
        option :result, Types::Strict::Symbol.enum(:one, :many), default: -> { self.class.result }

        # The foreign key for the association (optional)
        # @example
        #   option :foreign_key, :author_id
        option :foreign_key, Types::Symbol, optional: true

        # The primary key for the association (defaults to :id)
        # @example
        #   option :primary_key, :uuid
        option :primary_key, Types::Symbol, default: -> { :id }

        # The association to go through for *_through associations (optional)
        # @example
        #   option :through, :memberships
        option :through, optional: true

        # The view to use for the association (optional)
        # @example
        #   option :view, :sorted
        option :view, Types::Symbol, optional: true

        # The keys to use for combining associations (optional)
        # @example
        #   option :combine_keys, { author_id: :id }
        option :combine_keys, optional: true

        # A condition to apply to the association (optional)
        # @example
        #   option :condition, ->(relation) { relation.where(active: true) }
        option :condition, Types::Interface(:call), optional: true

        # Whether the association is polymorphic (defaults to false)
        # @example
        #   option :polymorphic, true
        option :polymorphic, default: -> { false }

        # The polymorphic type for the association (optional)
        # @example
        #   option :as, :commentable
        option :as, Types::Symbol, optional: true

        # Creates a new instance with processed options
        # @param opts [Hash] Options for the association
        # @return [Abstract] New instance of the association
        #
        # @example
        #   Abstract.new(
        #     source: Post,
        #     name: :comments,
        #     foreign_key: :post_id,
        #     result: :many
        #   )
        def self.new(**opts)
          options = process_options(Hash[opts])
          super(**options)
        end

        # Processes the options for the association
        # @param options [Hash] Raw options
        # @return [Hash] Processed options
        #
        # @example
        #   Abstract.process_options(
        #     relation: :comments,
        #     name: :recent_comments,
        #     through: :post
        #   )
        def self.process_options(options)
          options[:relation_name] = options.delete(:relation) if options.key?(:relation)

          ThroughIdentifier[*options.values_at(:source, :name, :through, :assoc_name)] do |settings|
            options[:through] = settings
          end

          PolymorphicIdentifier[*options.values_at(:source, :polymorphic, :as, :name)] do |settings|
            options[:polymorphic] = settings
          end

          options
        end

        # Returns the target of the association
        # @return [TargetIdentifier] The target identifier
        #
        # @example
        #   association = Abstract.new(source: Post, name: :comments)
        #   association.target # => #<TargetIdentifier @name=:comments, @relation_name=:comments>
        def target
          TargetIdentifier[name, relation_name]
        end

        # Builds the association
        # @param source [Object] The source object
        # @return [Object] The built association
        #
        # @example
        #   post = Post.new
        #   association = Abstract.new(source: Post, name: :comments)
        #   association.build_association(source: post)
        def build_association(source:)
          "::Resources::#{source.class.adapter.to_s.classify}::Associations::#{self.class.name.demodulize}"
            .constantize.new(self, source:, target: target.new(context: source.context))
        end

        # Calls the association
        # @param source [Object] The source object
        # @return [Object] The result of calling the association
        #
        # @example
        #   post = Post.new
        #   association = Abstract.new(source: Post, name: :comments)
        #   association.call_association(source: post)
        def call_association(source:)
          build_association(source:).call
        end

        # Joins the association
        # @param source [Object] The source object
        # @return [Object] The result of joining the association
        #
        # @example
        #   post = Post.new
        #   association = Abstract.new(source: Post, name: :comments)
        #   association.join_association(source: post)
        def join_association(source:)
          build_association(source:).join
        end

        # Uncomment to memoize the target method
        # memoize :target
      end
    end
  end
end
