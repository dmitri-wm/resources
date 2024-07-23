require '../spec_helper'

RSpec.describe Resources::Sql::Relation::UseSortingService do
  let(:test_class) do
    Class.new do
      include Resources::Sql::Relation::UseSortingService
    end
  end

  let(:instance) { test_class.new }
  let(:mock_dataset) { double('dataset') }
  let(:mock_relation) { double('relation', dataset: mock_dataset) }

  describe '.sorting_service' do
    it 'defines a default sorting service' do
      expect(test_class.sorting_service).to be_a(Proc)
    end

    it 'allows overriding the sorting service' do
      custom_service = ->(relation, params) { relation.dataset.reverse_order(params) }
      test_class.sorting_service custom_service
      expect(test_class.sorting_service).to eq(custom_service)
    end
  end

  describe '#sort' do
    before do
      allow(instance).to receive(:with).and_return(mock_relation)
    end

    it 'calls the sorting service with self and provided arguments' do
      sorting_params = { created_at: :desc }
      expect(mock_dataset).to receive(:order).with(sorting_params)
      instance.sort(sorting_params)
    end

    it 'wraps the result with #with' do
      expect(instance).to receive(:with).and_return(mock_relation)
      expect(instance.sort({})).to eq(mock_relation)
    end
  end
end
