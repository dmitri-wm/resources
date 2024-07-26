# spec/resources/initializer_spec.rb
require_relative 'spec_helper'

RSpec.describe Resources::Initializer do
  let(:test_class) do
    Class.new do
      extend Resources::Initializer

      param :one
      param :two
      option :three
      option :four, default: -> { 'default_four' }
    end
  end

  describe '#with' do
    let(:instance) { test_class.new('value_one', 'value_two', three: 'value_three') }

    it 'returns self when no changes are made' do
      expect(instance.with).to eq(instance)
    end

    it 'updates a positional argument' do
      new_instance = instance.with(one: 'new_one')
      expect(new_instance.one).to eq('new_one')
      expect(new_instance.two).to eq('value_two')
      expect(new_instance.three).to eq('value_three')
      expect(new_instance.four).to eq('default_four')
    end

    it 'updates a keyword argument' do
      new_instance = instance.with(three: 'new_three')
      expect(new_instance.one).to eq('value_one')
      expect(new_instance.two).to eq('value_two')
      expect(new_instance.three).to eq('new_three')
      expect(new_instance.four).to eq('default_four')
    end

    it 'updates multiple arguments' do
      new_instance = instance.with(one: 'new_one', three: 'new_three', four: 'new_four')
      expect(new_instance.one).to eq('new_one')
      expect(new_instance.two).to eq('value_two')
      expect(new_instance.three).to eq('new_three')
      expect(new_instance.four).to eq('new_four')
    end

    it 'does not modify the original instance' do
      instance.with(one: 'new_one', three: 'new_three')
      expect(instance.one).to eq('value_one')
      expect(instance.three).to eq('value_three')
    end
  end

  describe '#options' do
    let(:instance) { test_class.new('value_one', 'value_two', three: 'value_three') }

    it 'returns a hash of keyword arguments' do
      expect(instance.options).to eq({ three: 'value_three', four: 'default_four' })
    end

    it 'does not include positional arguments' do
      expect(instance.options.keys).not_to include(:one, :two)
    end
  end

  describe '#freeze' do
    let(:instance) { test_class.new('value_one', 'value_two', three: 'value_three') }

    it 'freezes the instance' do
      instance.freeze
      expect(instance).to be_frozen
    end

    it 'calculates options before freezing' do
      expect(instance).to receive(:options).and_call_original
      instance.freeze
    end
  end
end
