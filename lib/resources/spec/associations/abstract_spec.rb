# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Resources::Associations::Abstract do
  let(:definition) { double('definition') }
  let(:source) { double('source') }
  let(:target) { double('target') }

  subject { described_class.new(definition, source: source, target: target) }

  describe '#name' do
    it 'returns the name from the definition' do
      expect(definition).to receive(:name).and_return(:test_name)
      expect(subject.name).to eq(:test_name)
    end
  end

  describe '#view' do
    it 'returns the view from the definition' do
      expect(definition).to receive(:view).and_return(:test_view)
      expect(subject.view).to eq(:test_view)
    end
  end

  describe '#foreign_key' do
    it 'returns the foreign_key from the definition' do
      expect(definition).to receive(:foreign_key).and_return(:test_foreign_key)
      expect(subject.foreign_key).to eq(:test_foreign_key)
    end
  end

  describe '#result' do
    it 'returns the result from the definition' do
      expect(definition).to receive(:result).and_return(:many)
      expect(subject.result).to eq(:many)
    end
  end

  describe '#key' do
    context 'when definition has an :as option' do
      it 'returns the :as value' do
        expect(definition).to receive(:as).and_return(:test_as)
        expect(subject.key).to eq(:test_as)
      end
    end

    context 'when definition does not have an :as option' do
      it 'returns the name' do
        expect(definition).to receive(:as).and_return(nil)
        expect(definition).to receive(:name).and_return(:test_name)
        expect(subject.key).to eq(:test_name)
      end
    end
  end

  describe '#polymorphic?' do
    it 'returns the polymorphic value from the definition' do
      expect(definition).to receive(:polymorphic).and_return(true)
      expect(subject.polymorphic?).to eq(true)
    end
  end

  describe '#apply_view' do
    it 'calls the view method on the given relation' do
      relation = double('relation')
      expect(definition).to receive(:view).and_return(:test_view)
      expect(relation).to receive(:test_view)
      subject.apply_view(relation)
    end
  end

  describe '#combine_keys' do
    context 'when definition has combine_keys' do
      it 'returns the combine_keys from the definition' do
        expect(definition).to receive(:combine_keys).and_return({ source: :target })
        expect(subject.combine_keys).to eq({ source: :target })
      end
    end

    context 'when definition does not have combine_keys' do
      it 'returns a hash with source_key and target_key' do
        expect(definition).to receive(:combine_keys).and_return(nil)
        expect(subject).to receive(:source_key).and_return(:source_id)
        expect(subject).to receive(:target_key).and_return(:target_id)
        expect(subject.combine_keys).to eq({ source_id: :target_id })
      end
    end
  end
end
