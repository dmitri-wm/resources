require_relative '../../spec_helper'

RSpec.describe Resources::Associations::BelongsTo do
  let(:definition) { double('definition') }
  let(:source) { double('source') }
  let(:target) { double('target') }

  subject { described_class.new(definition, source: source, target: target) }

  describe '#call' do
    it 'raises NotImplementedError' do
      expect { subject.call }.to raise_error(NotImplementedError)
    end
  end

  describe '#foreign_key' do
    context 'when definition has a foreign_key' do
      it 'returns the foreign_key from the definition' do
        expect(definition).to receive(:foreign_key).and_return(:custom_foreign_key)
        expect(subject.foreign_key).to eq(:custom_foreign_key)
      end
    end

    context 'when definition does not have a foreign_key' do
      it 'returns the foreign_key from the source' do
        expect(definition).to receive(:foreign_key).and_return(nil)
        expect(target).to receive(:name).and_return(:target_name)
        expect(subject.foreign_key).to eq(:target_name_id)
      end
    end
  end

  describe '#associate' do
    it 'merges the foreign key and primary key' do
      expect(subject).to receive(:join_key_map).and_return(%i[fk pk])
      child = { id: 1 }
      parent = { pk: 10 }
      expect(subject.associate(child, parent)).to eq({ id: 1, fk: 10 })
    end
  end
end
