require_relative '../spec_helper'

RSpec.describe Resources::Associations::PolymorphicIdentifier do
  describe '.[]' do
    context 'with polymorphic: true' do
      it 'creates a new instance for belongs_to polymorphic association' do
        result = described_class[nil, true, nil, :holder]
        expect(result).to be_a(described_class)
        expect(result.foreign_type_key).to eq(:holder_type)
        expect(result.foreign_key).to eq(:holder_id)
      end
    end

    context 'with as: option' do
      it 'creates a new instance for has_many polymorphic association' do
        source = double('source', name: 'TestSource')
        result = described_class[source, nil, :holder, :items]
        expect(result).to be_a(described_class)
        expect(result.foreign_type_key).to eq(:holder_type)
        expect(result.foreign_key).to eq(:holder_id)
        expect(result.foreign_type).to eq('TestSource')
      end
    end

    context 'with invalid options' do
      it 'returns nil' do
        expect(described_class[nil, nil, nil, nil]).to be_nil
      end
    end
  end
end
