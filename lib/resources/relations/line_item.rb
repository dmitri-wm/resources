# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Relations
          class LineItem < Adapters::Sql
            use_ar_model ::LineItem

            belongs_to :prime_pco,
              foreign_key: :holder_id,
              relation: Relations::ChangeOrder,
              conditions: ->(scope) { scope.where(holder_type: 'PotentialChangeOrder') }
          end
        end
      end
    end
  end
end
