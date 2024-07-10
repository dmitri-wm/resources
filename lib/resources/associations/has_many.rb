# frozen_string_literal: true

require 'rom/associations/abstract'

module Resources
  module Associations
    class BelongsTo < Abstract
      def call(*)
        raise NotImplementedError
      end

      def foreign_key
        definition.foreign_key || target.foreign_key(source.name)
      end

      def associate(child, parent)
        pk, fk = join_key_map
        child.merge(fk => parent.fetch(pk))
      end

      protected

      # Return primary key on the source side
      #
      # @return [Symbol]
      def source_key
        source.schema.primary_key_name
      end

      # Return foreign key name on the target side
      #
      # @return [Symbol]
      def target_key
        foreign_key
      end

      memoize :foreign_key
    end
  end
end
