# frozen_string_literal: true

module Resources
  module Associations
    # Abstract association class
    #
    # @api public
    class Abstract
      extend Dry::Initializer

      include Memoizable

      # @return [Resources::Definition] Association configuration object
      param :definition

      option :source, reader: true

      option :target, reader: true

      # Return association canonical name
      #
      # @return [Symbol]
      #
      # @api public
      def name
        definition.name
      end

      # Return the name of a custom relation view that should be use to
      # extend or override default association view
      #
      # @return [Symbol]
      #
      # @api public
      def view
        definition.view
      end

      # Return association foreign key name
      #
      # @return [Symbol]
      #
      # @api public
      def foreign_key
        definition.foreign_key
      end

      # Return result type
      #
      # This can be either :one or :many
      #
      # @return [Symbol]
      #
      # @api public
      def result
        definition.result
      end

      # Return the name of a key in tuples under which loaded association data are returned
      #
      # @return [Symbol]
      #
      # @api public
      def key
        as || name
      end

      # Applies custom view to the default association view
      #
      # @return [Relation]
      #
      # @api protected
      def apply_view(schema, relation)
        view_rel = relation.public_send(view)
        schema.merge(view_rel.schema).uniq(&:key).call(view_rel)
      end

      # Return combine keys hash
      #
      # Combine keys are used for merging associated data together, typically these
      # are the same as fk<=>pk mapping
      #
      # @return [Hash<Symbol=>Symbol>]
      #
      # @api public
      def combine_keys
        definition.combine_keys || { source_key => target_key }
      end

      # Return names of source PKs and target FKs
      #
      # @return [Array<Symbol>]
      #
      # @api private
      def join_key_map
        join_keys.to_a.flatten(1).map(&:key)
      end

      # Return target relation configured as a combine node
      #
      # @return [Relation]
      #
      # @api private
      def node
        target.with(
          name: target.name.as(key),
          meta: { keys: combine_keys, combine_type: result, combine_name: key }
        )
      end

      # Prepare association's target relation for composition
      #
      # @return [Relation]
      #
      # @api private
      def prepare(target)
        if override?
          target.public_send(view)
        else
          call(target:)
        end
      end

      # Return if this association's source relation is the same as the target
      #
      # @return [Boolean]
      #
      # @api private
      def self_ref?
        source.name.dataset == target.name.dataset
      end

      memoize :combine_keys, :join_key_map
    end
  end
end
