# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Relations
          class ChangeEventLineItem < Adapters::Sql
            use_filters_service ::Financials::Private::ChangeEvents::Items::Filters::ChangeEventLineItem
            use_sorting_service ->(scope, _context) { scope.order(sorting_params) }

            belongs_to :prime_pco_line_item,
              foreign_key: :prime_potential_change_order_line_item_id,
              relation: Relations::LineItem
            belongs_to :prime_pco, through: :prime_pco_line_item, source: :holder
          end
        end
      end
    end
  end
end
