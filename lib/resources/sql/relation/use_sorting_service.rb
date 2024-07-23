# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      # UseSortingService module provides sorting functionality for SQL relations
      module UseSortingService
        extend Concern

        included do
          # Defines a class-level sorting service
          defines :sorting_service
          delegate :sorting_service, to: :class

          # Default sorting service implementation
          # @param relation [Relation] The relation to sort
          # @param sorting_params [Hash] The sorting parameters
          # @return [Relation] The sorted relation
          sorting_service ->(relation, sorting_params) { relation.dataset.order(sorting_params) }
        end

        # Sorts the relation using the defined sorting service
        #
        # @param args [Array] Arguments to pass to the sorting service
        # @return [Relation] A new relation with the sorting applied
        def sort(*args)
          with(sorting_service.call(self, *args))
        end
      end
    end
  end
end
