# frozen_string_literal: true

module Resources
  module Associations
    # Represents a belongs_to association between resources
    class BelongsTo < Abstract
      # @note This method is not implemented in the BelongsTo class
      # @raise [NotImplementedError] when called
      def call(*)
        raise NotImplementedError
      end

      # Returns the foreign key for the association
      #
      # @return [Symbol] The foreign key, either from the definition or derived from the target name
      # @example
      #   belongs_to.foreign_key #=> :user_id
      def foreign_key
        definition.foreign_key || "#{target.name}_id".to_sym
      end

      # Associates a child resource with a parent resource
      #
      # @param child [Hash] The child resource to be associated
      # @param parent [Hash] The parent resource to associate with
      # @return [Hash] The child resource with the foreign key set to the parent's primary key
      # @example
      #   belongs_to.associate({name: 'Post'}, {id: 1, name: 'User'}) #=> {name: 'Post', user_id: 1}
      def associate(child, parent)
        fk, pk = join_key_map
        child.merge(fk => parent.fetch(pk))
      end

      protected

      # Returns the source key for the association
      #
      # @return [Symbol] The foreign key of the association
      def source_key
        foreign_key
      end

      # Returns the target key for the association
      #
      # @return [Symbol] The primary key of the target resource
      def target_key
        definition.primary_key
      end

      memoize :foreign_key
    end
  end
end
