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
