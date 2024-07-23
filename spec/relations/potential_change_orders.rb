# frozen_string_literal: true

# domain: Change Events

class PotentialChangeOrders < Resources::Sql::Relation::ActiveRecord
  use_ar_model PotentialChangeOrder

  associate do
    has_many :line_items, as: :holder, relation: :line_items, joinable: :array
    has_many :prime_celis, through: :line_items, source: :prime_celis, joinable: :array
    has_many :commitment_celis, through: :line_items, source: :commitment_celis, joinable: :array
    has_many :commitment_celis,
             foreign_key: %i[
               commitment_contract_line_item_id
               commitment_potential_change_order_line_item_id
             ], at: :change_event_line_items, joinable: :array
    belongs_to :holder, polymorphic: true
  end
end
