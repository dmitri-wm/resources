class ChangeEventLineItem < ActiveRecord::Base
  belongs_to :prime_potential_change_order_line_item, class_name: :LineItem, optional: true
  belongs_to :commitment_potential_change_order_line_item, class_name: :LineItem, optional: true
  belongs_to :commitment_contract_line_item, class_name: :LineItem, optional: true
  belongs_to :change_event
end
