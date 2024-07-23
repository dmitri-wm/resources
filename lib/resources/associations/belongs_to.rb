# frozen_string_literal: true

module Resources
  module Associations
    class BelongsTo < Abstract
      def call(*)
        raise NotImplementedError
      end

      def foreign_key
        definition.foreign_key || "#{target.name}_id".to_sym
      end

      def associate(child, parent)
        fk, pk = join_key_map
        child.merge(fk => parent.fetch(pk))
      end

      protected

      def source_key
        foreign_key
      end

      def target_key
        definition.primary_key
      end

      memoize :foreign_key
    end
  end
end
