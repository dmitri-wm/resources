# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      # QueryService class provides a query service-based implementation of the SQL Relation
      class QueryService < ActiveRecord
        class << self
          # @!attribute [rw] query_service
          #   @return [#call] The query service to be used
          attr_accessor :query_service

          # Sets the query service to be used by this relation
          #
          # @param service [#call] The query service to be used
          # @return [void]
          def use_query_service(service)
            self.query_service = service
          end
        end

        # @!attribute [r] filters
        #   @return [Hash] The filters to be applied to the query
        option :filters, Hash, default: -> { {} }

        # @!attribute [r] dataset
        #   @return [Dataset] The dataset representing the query result
        option :dataset, default: -> { Dataset.new(base_query) }

        # Applies additional filters to the relation
        #
        # @param filters [Hash] The filters to be applied
        # @return [QueryService] A new instance with the filters applied
        def filter(filters)
          new(filters: filters.merge(filters))
        end

        # Executes the base query using the query service
        #
        # @return [ActiveRecord::Relation] The result of the base query
        def base_query
          query_service.call(context:, filters:).query
        end
      end
    end
  end
end
