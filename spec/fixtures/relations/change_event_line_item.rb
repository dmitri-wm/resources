module Relations
  class ChangeEventLineItem < Resources::Relations::Adapters::Sql
    use_ar_model ::ChangeEventLineItem

    belongs_to :prime_pco_line_item,
               foreign_key: :prime_potential_change_order_line_item_id,
               relation: LineItem
    belongs_to :commitment_pco_line_item,
               foreign_key: :commitment_potential_change_order_line_item_id,
               relation: LineItem

    belongs_to :prime_pco, through: :prime_pco_line_item, source: :holder
    belongs_to :commitment_pco, through: :commitment_pco_line_item,
                                source: :holder
  end
end