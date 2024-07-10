# frozen_string_literal: true

module Resources
  module Associations
    class HasMany < Abstract
      def call(*)
        raise NotImplementedError
      end

      def foreign_key
        definition.foreign_key || source.foreign_key(target.name)
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
