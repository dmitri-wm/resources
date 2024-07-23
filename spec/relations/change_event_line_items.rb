# frozen_string_literal: true

class ChangeEventLineItems < Resources::Sql::ActiveRecord
  use_ar_model ChangeEventLineItem

  associate do
    belongs_to :line_item,
               foreign_key: :prime_potential_change_order_line_item_id,
               primary_key: :id,
               relation: LineItems, joinable: :array
    has_many :commitment_line_items,
             foreign_key: %i[commitment_potential_change_order_line_item_id prime_potential_change_order_line_item_id],
             primary_key: :id,
             relation: LineItems, joinable: :ary_sql
    belongs_to :prime_line_item,
               foreign_key: :prime_potential_change_order_line_item_id, primary_key: :id,
               relation: LineItems, joinable: :array
    has_one :potential_change_order, through: :line_item, source: :holder, joinable: :ary_sql
  end
end
