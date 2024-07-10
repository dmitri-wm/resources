module Relations
  class LineItem < Resources::Relations::Adapters::Sql
    use_ar_model ::LineItem

    belongs_to :potential_change_order,
               foreign_key: :holder_id,
               relation: PotentialChangeOrder

    belongs_to :contract,
               foreign_key: :holder_id,
               relation: Contract
  end
end