# frozen_string_literal: true

module Resources
  module Associations
    # Abstract association class
    #
    # @api public
    class Abstract
      extend Dry::Initializer

      include Memoizable

      param :definition

      option :source, reader: true

      option :target, reader: true

      def name
        definition.name
      end

      def view
        definition.view
      end

      def foreign_key
        definition.foreign_key
      end

      def result
        definition.result
      end

      def key
        definition.as || name
      end

      def polymorphic?
        definition.polymorphic
      end

      def apply_view(relation)
        relation.public_send(view)
      end

      def combine_keys
        definition.combine_keys || { source_key => target_key }
      end

      def join_key_map
        join_keys.to_a.flatten(1)
      end

      def node
        target.with(
          name: target.name.as(key),
          meta: { keys: combine_keys, combine_type: result, combine_name: key }
        )
      end

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
