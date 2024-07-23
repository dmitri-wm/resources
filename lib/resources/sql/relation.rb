# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    # Relation module provides a factory method for creating SQL-based relations
    module Relation
      # Factory method to create a specific type of SQL relation
      #
      # @param type [Symbol] The type of relation to create (:AR or :Service)
      # @return [Class] The relation class corresponding to the given type
      # @raise [ArgumentError] If an unknown relation type is provided
      #
      # @example Create an ActiveRecord relation
      #   relation_class = Resources::Sql::Relation[:AR]
      #
      # @example Create a QueryService relation
      #   relation_class = Resources::Sql::Relation[:Service]
      def self.[](type)
        {
          AR: ActiveRecord,
          Service: QueryService
        }[type].tap do |klass|
          raise ArgumentError, "Unknown relation type: #{type}" unless klass
        end
      end
    end
  end
end
