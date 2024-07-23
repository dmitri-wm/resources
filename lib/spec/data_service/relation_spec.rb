require_relative '../spec_helper'

RSpec.describe Resources::DataService::Relation do
  let(:context) { double('Context') }

  # Define a concrete data service class for testing
  let(:test_data_service_class) do
    Class.new do
      attr_reader :context

      def initialize(context:)
        @context = context
      end

      def find_some(options:, filters:)
        # Simulate fetching data
        [{ id: 1, name: 'Test' }, { id: 2, name: 'Example' }]
      end
    end
  end

  # Define a concrete relation class for testing
  let(:test_relation_class) do
    class TestRelation < Resources::DataService::Relation
      use_data_service TestDataService
      service_call ->(dataset) { dataset.datasource.find_some(options: {}, filters: {}) }
      dataset_config proc { option :custom_option, default: -> { 'default' } }
    end

    TestRelation
  end

  before do
    stub_const('TestDataService', test_data_service_class)
    stub_const('TestRelation', test_relation_class)
  end

  describe 'integration with Dataset' do
    subject { TestRelation.new(context: context) }

    it 'creates a Dataset with the correct data service' do
      expect(subject.dataset.datasource).to be_a(TestDataService)
      expect(subject.dataset.datasource.context).to eq(context)
    end

    it 'applies the dataset_config to the Dataset' do
      subject.dataset
      expect(subject.dataset.custom_option).to eq('default')
    end

    it 'fetches data using the service_call' do
      result = subject.dataset.to_a
      expect(result).to eq([{ id: 1, name: 'Test' }, { id: 2, name: 'Example' }])
    end

    it 'allows chaining of dataset methods' do
      filtered_dataset = subject.dataset.where(status: 'active')
      expect(filtered_dataset).to be_a(Resources::DataService::Dataset)
      expect(filtered_dataset.filters).to eq(status: 'active')
    end
  end

  describe 'custom service_call' do
    let(:test_relation_with_custom_service_call) do
      class TestRelationCustomServiceCall < Resources::DataService::Relation
        use_data_service TestDataService
        service_call ->(dataset) { dataset.datasource.find_some(options: {}, filters: { custom: true }) }
      end

      TestRelationCustomServiceCall
    end

    subject { test_relation_with_custom_service_call.new(context: context) }

    it 'uses the custom service_call to fetch data' do
      expect(subject.dataset.datasource).to receive(:find_some).with(options: {}, filters: { custom: true })
      subject.dataset.to_a
    end
  end

  describe 'relation inheritance' do
    let(:child_relation_class) do
      class ChildRelation < TestRelation
        use_data_service TestDataService

        dataset_config proc {
          option :child_option, default: -> { 'child default' }
        }
      end

      ChildRelation
    end

    subject { child_relation_class.new(context: context) }

    it 'inherits and extends dataset_config' do
      expect(subject.dataset.child_option).to eq('child default')
    end
  end
end
