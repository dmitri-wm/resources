# frozen_string_literal: true

module Resources
  module Associations
    # Abstract association class that defines the basic structure and behavior
    # for associations between resources.
    #
    # @api public
    class Abstract
      extend Dry::Initializer
      include Memoizable

      # @!attribute [r] definition
      #   @return [Object] The association definition object
      param :definition

      # @!attribute [r] source
      #   @return [Object] The source of the association
      option :source, reader: true

      # @!attribute [r] target
      #   @return [Object] The target of the association
      option :target, reader: true

      # Returns the name of the association
      #
      # @return [Symbol] The association name
      def name
        definition.name
      end

      # Returns the view method name for the association
      #
      # @return [Symbol, nil] The view method name or nil if not defined
      def view
        definition.view
      end

      # Returns the foreign key for the association
      #
      # @return [Symbol, nil] The foreign key or nil if not defined
      def foreign_key
        definition.foreign_key
      end

      # Returns the result type of the association
      #
      # @return [Symbol] The result type (e.g., :one, :many)
      def result
        definition.result
      end

      # Returns the key used for the association
      #
      # @return [Symbol] The association key (alias or name)
      def key
        definition.as || name
      end

      # Checks if the association is polymorphic
      #
      # @return [Boolean] True if the association is polymorphic, false otherwise
      def polymorphic?
        definition.polymorphic
      end

      # Applies the view method to the given relation
      #
      # @param relation [Object] The relation object to apply the view on
      # @return [Object] The result of applying the view method
      def apply_view(relation)
        relation.public_send(view)
      end

      # Returns the combine keys for the association
      #
      # @return [Hash] A hash of source and target keys for combining
      def combine_keys
        definition.combine_keys || { source_key => target_key }
      end

      # Returns the join key map for the association
      #
      # @return [Array] A flattened array of join keys
      def join_key_map
        join_keys.to_a.flatten(1)
      end

      # Creates a node representation of the target with association metadata
      #
      # @return [Object] The target object with additional metadata
      def node
        target.with(
          name: target.name.as(key),
          meta: { keys: combine_keys, combine_type: result, combine_name: key }
        )
      end

      # Prepares the target for the association
      #
      # @param target [Object] The target object to prepare
      # @return [Object] The prepared target object
      def prepare(target)
        if view
          target.public_send(view)
        else
          call(target:)
        end
      end

      memoize :combine_keys, :join_key_map
    end
  end
end
