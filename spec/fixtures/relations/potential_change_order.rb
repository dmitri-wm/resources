module Relations
  class Base < Relation[:Service]
    TYPES_MAP = { prime: 'PrimeChangeOrder', commitment: 'CommitmentChangeOrder' }.freeze

    service ::Financials::Public::ChangeOrders::Service

    def fetch_data = dataset.find_some(options: { system_access: true },filters:).value![:change_orders]
  end

  def self.new(**options)
    if context.send(:"#{type}_change_order_single_tier?")
      ChangeOrders::SingleTier.new(**options)
    else
      ChangeOrders::MultiTier.new(**options)
    end
  end
end