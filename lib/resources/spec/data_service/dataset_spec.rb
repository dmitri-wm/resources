require_relative '../spec_helper'

RSpec.describe Resources::DataService::Dataset, aggregate_failures: true do
  let(:datasource) { double('datasource', find_some: -> { [1, 2, 3] }) }
  let(:options) { { service_call: ->(dataset) { dataset.datasource.find_some(filters:, options: {}) } } }
  let(:custom_class) do
    class CustomRelation < Resources::DataService::Relation
      service_call ->(dataset) { dataset }
    end

    CustomRelation
  end

  before do
    stub_const('CustomRelation', custom_class)
  end

  subject { described_class.new(datasource, **options) }

  describe '#initialize' do
    context 'with default options' do
      it 'initializes with default values' do
        expect(subject.filters).to eq({})
        expect(subject.page).to eq(1)
        expect(subject.per_page).to eq(10)
        expect(subject.sort).to eq({})
      end
    end

    context 'with custom options' do
      let(:options) { { service_call: -> {}, filters: { status: 'active' }, page: 2, per_page: 20, sort: { created_at: :desc } } }

      it 'initializes with custom values' do
        expect(subject.filters).to eq({ status: 'active' })
        expect(subject.page).to eq(2)
        expect(subject.per_page).to eq(20)
        expect(subject.sort).to eq({ created_at: :desc })
      end
    end

    context 'with additional setup' do
      let(:options) { { service_call: -> {}, config: { relation_name: :custom_relation, dataset_config: proc { option :additional, optional: true, default: -> { 'test' } } } } }

      it 'should return a custom class' do
        expect(subject.class.name).to eq('Resources::DataService::Dataset::CustomRelation')
      end
    end
  end

  describe '#to_a' do
    it 'calls find_some on datasource with correct parameters' do
      expect(datasource).to receive(:find_some).with(options: {}, filters: {})
      subject.to_a
    end
  end

  describe '#where' do
    let(:new_conditions) { { status: 'active' } }

    it 'returns a new instance with merged filters' do
      new_dataset = subject.where(new_conditions)
      expect(new_dataset).to be_a(described_class)
      expect(new_dataset.filters).to eq(new_conditions)
    end
  end

  describe '#fetch_custom_class' do
    subject { described_class }

    let(:relation_name) { :custom_relation }
    let(:dataset_config) { proc {} }

    context 'when custom class is already defined' do
      it 'returns the existing constant' do
        result = subject.fetch_custom_class(relation_name: relation_name, dataset_config: dataset_config)
        expect(result.name).to eq('Resources::DataService::Dataset::CustomRelation')
      end
    end

    context 'when custom class is not defined' do
      it 'creates a new class' do
        result = subject.fetch_custom_class(relation_name: relation_name, dataset_config: dataset_config)
        expect(result).to be_a(Class)
        expect(result.superclass).to eq(Resources::DataService::Dataset::CustomRelation)
      end
    end
  end

  describe '#additional_setup?' do
    subject { described_class }

    context 'when config is present' do
      let(:options) { { config: { relation_name: :custom, dataset_config: proc {} } } }

      it 'returns true' do
        expect(subject.additional_setup?(options)).to be true
      end
    end

    context 'when config is not present' do
      it 'returns false' do
        expect(subject.additional_setup?(options)).to be false
      end
    end
  end
end
