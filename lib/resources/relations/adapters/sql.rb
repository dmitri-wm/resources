# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Relations
          module Adapters
            class Sql < Base
              include Lib::UseFiltersService
              include Lib::Sql::UseActiveRecord
              attr_accessor :cached_query

              use_sorting_service ->(data, sorting_params, _context) { data.order(sorting_params) }

              # @return [ActiveRecord::Relation]
              def fetch = fetch_query.then(&execute_query)

              def fetch_query = cached_query || build_query

              def build_query = initial_scope.then(&apply_queries).tap(&cache_query)

              def cache_query = ->(q) { self.cached_query = q }

              def apply_queries = apply_where >> select_fields >> sort_data >> paginate_data

              def select_fields
                ->(scope) { fetch_fields_to_select.presence ? scope.select(*fetch_fields_to_select) : scope }
              end

              def to_view
                transform >> to_entities >> store_collection
              end
            end
          end
        end
      end
    end
  end
end
