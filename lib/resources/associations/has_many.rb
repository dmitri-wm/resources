# frozen_string_literal: true

module Resources
  module Associations
    # Represents a has_many association between resources
    class HasMany < Abstract
      # @note This method is not implemented in the HasMany class
      # @raise [NotImplementedError] when called
      def call(*)
        raise NotImplementedError
      end

      # Returns the foreign key for the association
      #
      # @return [Symbol] The foreign key, either from the definition or derived from the source name
      # @example
      #   has_many.foreign_key #=> :user_id
      def foreign_key
        definition.foreign_key || "#{source.name}_id".to_sym
      end

      # Associates a child resource with a parent resource
      #
      # @param child [Hash] The child resource to be associated
      # @param parent [Hash] The parent resource to associate with
      # @return [Hash] The child resource with the foreign key set to the parent's primary key
      # @example
      #   has_many.associate({name: 'Post'}, {id: 1, name: 'User'}) #=> {name: 'Post', user_id: 1}
      def associate(child, parent)
        # Add validation for child and parent parameters here
        pk, fk = join_key_map
        child.merge(fk => parent.fetch(pk))
      end

      protected

      # Returns the source key for the association
      #
      # @return [Symbol] The primary key of the source resource
      def source_key
        definition.primary_key
      end

      # Returns the target key for the association
      #
      # @return [Symbol] The foreign key of the target resource
      def target_key
        foreign_key
      end

      memoize :foreign_key
    end
  end
end
