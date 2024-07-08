# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Resources::Relations::Adapters::Sql do
  class << self
    const_set("RelationsPotentialChangeOrder",
              Class.new(Resources::Relations::Adapters::Sql) do
                use_ar_model ::PotentialChangeOrder
              end)
    const_set("RelationsContract",
              Class.new(Resources::Relations::Adapters::Sql) do
                use_ar_model ::Contract
              end)

    const_set("RelationsLineItem", Class.new(Resources::Relations::Adapters::Sql) do
      use_ar_model ::LineItem

      belongs_to :potential_change_order,
                 foreign_key: :holder_id,
                 relation: RelationsPotentialChangeOrder

      belongs_to :contract,
                 foreign_key: :holder_id,
                 relation: RelationsContact
    end)

    const_set("RelationsChangeEventLineItem",
              Class.new(Resources::Relations::Adapters::Sql) do
                use_ar_model ::ChangeEventLineItem

                belongs_to :prime_pco_line_item,
                           foreign_key: :prime_potential_change_order_line_item_id,
                           relation: RelationLineItem
                belongs_to :commitment_pco_line_item,
                           foreign_key: :commitment_potential_change_order_line_item_id,
                           relation: RelationLineItem

                belongs_to :prime_pco, through: :prime_pco_line_item, source: :holder
                belongs_to :commitment_pco, through: :commitment_pco_line_item,
                                            source: :holder
              end)
  end

  let(:service_context) { double(company_id: 1, user_id: 1, project_id: 1) }
  let(:service) { Relations::ChangeEventLineItem.new(context: service_context) }

  context "query" do
    let!(:single_celi) { create(:change_event_line_item) }

    it "should be somehow true" do
      puts service.all.inspect
    end
  end
end
