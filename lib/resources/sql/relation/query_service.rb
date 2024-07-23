# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      class QueryService < ActiveRecord
        class << self
          attr_accessor :query_service

          def use_query_service(service)
            self.query_service = service
          end
        end

        option :filters, Hash, default: -> { {} }
        option :dataset, default: -> { Dataset.new(base_query) }

        def filter(filters)
          new(filters: filters.merge(filters))
        end

        def base_query
          query_service.call(context:, filters:).query
        end
      end
    end
  end
end
