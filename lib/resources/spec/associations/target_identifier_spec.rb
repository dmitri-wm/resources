# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Resources::Associations::TargetIdentifier do
  describe '.call' do
    it 'resolves target' do
      target = double('target')
      allow(described_class).to receive(:resolve_target).and_return(target)
      expect(described_class.call(:users, nil)).to eq(target)
    end
  end

  let!(:relation_class) do
    class Dummy < Resources::Relation; end
    Dummy
  end

  describe '.resolve_target' do
    context 'when relation is nil' do
      it 'infers the target from the name' do
        expect(described_class.send(:resolve_target, :dummies, nil)).to eq(relation_class)
      end
    end

    context 'when relation is a Resources::Relation subclass' do
      it 'returns the relation class' do
        expect(described_class.send(:resolve_target, :users, relation_class)).to eq(relation_class)
      end
    end

    context 'when relation is a Symbol or String' do
      it 'resolves the relation' do
        stub_const('User', Class.new)
        expect(described_class.send(:resolve_target, :users, 'User')).to eq(User)
      end
    end

    context 'when relation is unknown' do
      it 'raises an ArgumentError' do
        expect { described_class.send(:resolve_target, :users, Object.new) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.resolve_relation' do
    context 'when relation is in registry' do
      before do
        stub_const('User', Class.new)
        allow(Resources::Relation).to receive(:relations).and_return({ users: User })
      end

      it 'returns the relation from the registry' do
        expect(described_class.send(:resolve_relation, :users)).to eq(User)
      end
    end

    context 'when relation is in CamelCase' do
      it 'constantizes the relation name' do
        stub_const('User', Class.new)
        expect(described_class.send(:resolve_relation, 'User')).to eq(User)
      end
    end

    context 'when relation cannot be resolved' do
      it 'raises a NameError' do
        expect { described_class.send(:resolve_relation, :unknown) }.to raise_error(NameError)
      end
    end
  end

  describe '.relation_class?' do
    it 'returns true for Resources::Relation subclasses' do
      expect(described_class.send(:relation_class?, relation_class)).to be true
    end

    it 'returns false for non-Resources::Relation classes' do
      expect(described_class.send(:relation_class?, Class.new)).to be nil
    end
  end

  describe '.in_registry?' do
    before do
      stub_const('User', Class.new)
      allow(Resources::Relation).to receive(:relations).and_return({ users: User })
    end

    it 'returns true for relations in the registry' do
      expect(described_class.send(:in_registry?, :users)).to be true
    end

    it 'returns false for relations not in the registry' do
      expect(described_class.send(:in_registry?, :unknown)).to be false
    end
  end

  describe '.camel_case?' do
    it 'returns true for CamelCase strings' do
      expect(described_class.send(:camel_case?, 'User')).to be true
    end

    it 'returns false for non-CamelCase strings' do
      expect(described_class.send(:camel_case?, 'user')).to be false
    end
  end
end
