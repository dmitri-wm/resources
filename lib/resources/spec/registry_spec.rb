# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe Resources::Registry, aggregate_failure: true do
  let(:test_class) do
    Class.new do
      include Resources::Registry

      register into: :test_registry, by: :name, default: -> { hash }
    end.then do |klass|
      stub_const('TestClass', klass)
    end
  end

  describe '.register' do
    it 'creates a registry method' do
      expect(test_class).to respond_to(:test_registry)
      expect(test_class.test_registry.ancestors).to include(Resources::Registry::Base)
    end

    it 'creates a [] method that delegates to the registry' do
      inherited = Class.new(test_class)
      expect(test_class.test_registry).to receive(:[]).with(inherited.hash).and_return(inherited)
      expect(test_class.test_registry[inherited.hash]).to eq(inherited)
    end
  end

  describe '.registry_key' do
    it 'allows setting a custom registry key' do
      subclass = Class.new(test_class) { test_registry_name :custom_relation }
      expect(test_class[:custom_relation]).to eq(subclass)
    end
  end
end

RSpec.describe Resources::Registry::Base do
  let(:registry) { stub_const('CustomRegistry', Class.new(described_class)) }

  describe '#[]=' do
    it 'allows registering a new resource' do
      resource = Class.new
      registry[:test] = resource
      expect(registry[:test]).to eq(resource)
    end

    it 'raises an error when trying to register the same key twice' do
      registry[:test] = Class.new
      expect { registry[:test] = Class.new }.to raise_error(KeyError, 'test is already registered')
    end
  end

  describe '#[]' do
    it 'returns the registered resource' do
      resource = Class.new
      registry[:test] = resource
      expect(registry[:test]).to eq(resource)
    end

    it 'raises an error when trying to access an unregistered resource' do
      expect { registry[:nonexistent] }.to raise_error(KeyError, 'nonexistent is not registered')
    end
  end

  describe '#key?' do
    it 'returns true for registered resources' do
      registry[:test] = Class.new
      expect(registry.key?(:test)).to be true
    end

    it 'returns false for unregistered resources' do
      expect(registry.key?(:nonexistent)).to be false
    end
  end
end
