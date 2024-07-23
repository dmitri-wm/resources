module Relations
  class ChangeEventLineItem < Resources::Adapters::Ar
    dataset ::ChangeEventLineItem

    def change_orders = prime_line_items.holders.prime
    def prime_line_items = line_items.where(id: prime_line_item_ids)
    def prime_line_item_ids = pluck(:prime_potential_change_order_line_item_id)

    def commitments = commitment_line_items.holders.commitment
    def commitment_line_items = line_items.where(id: commitment_line_item_ids)

    def commitment_line_item_ids
      select('COALESCE(commitment_contract_line_item_id, commitment_potential_change_order_line_item_id) AS commitment_line_item_id').distinct.map(&:commitment_line_item_id)
    end

    def line_items = LineItem.new(context:)
  end
end