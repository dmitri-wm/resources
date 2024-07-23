# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      module UseSortingService
        extend Concern

        included do
          defines :sorting_service
          delegate :sorting_service, to: :class

          sorting_service ->(relation, sorting_params) { relation.dataset.order(sorting_params) }
        end

        def sort(*args)
          with(sorting_service.call(self, *args))
        end
      end
    end
  end
end
