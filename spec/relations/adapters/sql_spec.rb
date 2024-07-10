# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Resources::Relations::Adapters::Sql do
  let(:service_context) { double(company_id: 1, user_id: 1, project_id: 1) }
  let(:service) { Relations::ChangeEventLineItem.new(context: service_context) }

  context "query" do
    let!(:single_celi) { create(:change_event_line_item) }

    it "should be somehow true" do
      service.all.inspect
    end
  end
end
