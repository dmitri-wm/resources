# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Resources::Associations::HasManyThrough do
  let(:definition) { double('definition', source: double('source'), target: double('target')) }
  let(:source) { double('source') }
  let(:target) { double('target') }
  let(:through) { double('through') }

  subject { described_class.new(definition, source: source, target: target) }

  before do
    allow(definition).to receive(:through).and_return(through)
    allow(through).to receive(:join_relation).and_return(double('join_relation'))
  end

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
      it 'returns the foreign_key from the join_relation' do
        expect(definition).to receive(:foreign_key).and_return(nil)
        expect(source).to receive(:name).and_return(:source_name)
        expect(subject.join_relation).to receive(:foreign_key).with(:source_name).and_return(:inferred_foreign_key)
        expect(subject.foreign_key).to eq(:inferred_foreign_key)
      end
    end
  end

  describe '#associate' do
    it 'associates children with parent' do
      expect(subject).to receive(:join_key_map).and_return([%i[spk sfk], %i[tfk tpk]])
      children = [{ spk: 1 }, { spk: 2 }]
      parent = { tpk: 10 }
      expect(subject.associate(children, parent)).to eq([{ sfk: 1, tfk: 10 }, { sfk: 2, tfk: 10 }])
    end

    it 'handles array of parents' do
      expect(subject).to receive(:join_key_map).and_return([%i[spk sfk], %i[tfk tpk]]).at_most(3).times
      children = [{ spk: 1 }, { spk: 2 }]
      parents = [{ tpk: 10 }, { tpk: 20 }]
      expect(subject.associate(children, parents)).to eq([
                                                           { sfk: 1, tfk: 10 }, { sfk: 2, tfk: 10 },
                                                           { sfk: 1, tfk: 20 }, { sfk: 2, tfk: 20 }
                                                         ])
    end
  end
end
