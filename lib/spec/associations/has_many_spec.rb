# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Resources::Associations::HasMany do
  let(:definition) { double('definition') }
  let(:source) { double('source') }
  let(:target) { double('target') }
  let(:association) { described_class.new(definition, source:, target:) }

  describe '#call' do
    it 'raises NotImplementedError' do
      expect { association.call }.to raise_error(NotImplementedError)
    end
  end

  describe '#foreign_key' do
    it 'returns the foreign key from the definition' do
      expect(definition).to receive(:foreign_key).and_return(:some_foreign_key)
      expect(association.foreign_key).to eq(:some_foreign_key)
    end

    it 'memoizes the result' do
      expect(definition).to receive(:foreign_key).once.and_return(:some_foreign_key)
      2.times { association.foreign_key }
    end
  end

  describe '#associate' do
    let(:child) { { id: 1 } }
    let(:parent) { { id: 2 } }
    let(:join_key_map) { %i[id parent_id] }

    before do
      allow(association).to receive(:join_key_map).and_return(join_key_map)
    end

    it 'merges the foreign key into the child' do
      result = association.associate(child, parent)
      expect(result).to eq({ id: 1, parent_id: 2 })
    end
  end

  describe '#source_key' do
    it 'returns the primary key from the definition' do
      expect(definition).to receive(:primary_key).and_return(:some_primary_key)
      expect(association.send(:source_key)).to eq(:some_primary_key)
    end
  end

  describe '#target_key' do
    it 'returns the foreign key' do
      allow(association).to receive(:foreign_key).and_return(:some_foreign_key)
      expect(association.send(:target_key)).to eq(:some_foreign_key)
    end
  end
end
