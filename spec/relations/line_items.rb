# frozen_string_literal: true

# domain: Change Events

class LineItems < Resources::Sql::Relation::ActiveRecord
  use_ar_model LineItem

  associate do
    has_many :change_event_line_items,
             relation: ChangeEventLineItems,
             foreign_key: %i[
               prime_potential_change_order_line_item_id
               commitment_contract_line_item_id
               commitment_potential_change_order_line_item_id
             ], primary_key: :id, joinable: :array
    has_many :prime_celis,
             relation: ChangeEventLineItems,
             foreign_key: :prime_potential_change_order_line_item_id,
             joinable: :array
    has_many :commitment_celis,
             foreign_key: %i[
               commitment_contract_line_item_id
               commitment_potential_change_order_line_item_id
             ], at: :change_event_line_items, joinable: :array
    belongs_to :holder, polymorphic: true
  end
end
