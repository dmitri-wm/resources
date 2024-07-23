require_relative '../spec_helper'

RSpec.describe Resources::Sql::Relation::ActiveRecord do
  let(:ar_model) { class_double('ActiveRecord::Base', column_names: %w[id company_id project_id name]) }
  let(:context) { double('context', company_id: 1, project_id: 2) }

  before do
    described_class.use_ar_model(ar_model)
    allow(ar_model).to receive(:column_names).and_return(%w[id company_id project_id name])
  end

  describe '.use_ar_model' do
    it 'sets the ar_model class attribute' do
      expect(described_class.ar_model).to eq(ar_model)
    end

    it 'sets the context_columns class attribute' do
      expect(described_class.context_columns).to eq(%i[company_id project_id])
    end
  end

  describe '#context_conditions' do
    subject { described_class.new(context:) }

    it 'returns a hash with context conditions' do
      expect(subject.context_conditions).to eq({ company_id: 1, project_id: 2 })
    end
  end

  describe '#base_query' do
    subject { described_class.new(context:) }

    it 'calls where on ar_model with context conditions' do
      expect(ar_model).to receive(:where).with({ company_id: 1, project_id: 2 })
      subject.base_query
    end
  end

  describe '#to_a' do
    let(:dataset) { instance_double(Resources::Sql::Dataset) }
    subject { described_class.new(context:, dataset:) }

    it 'calls to_a on the dataset' do
      expect(dataset).to receive(:to_a)
      subject.to_a
    end
  end

  describe 'forwarded methods' do
    let(:dataset) { instance_double(Resources::Sql::Dataset) }
    subject { described_class.new(context:, dataset:) }

    it 'forwards methods to dataset' do
      expect(dataset).to receive(:where).with(name: 'test')
      subject.where(name: 'test')
    end
  end
end
