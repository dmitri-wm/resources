require_relative '../spec_helper'

RSpec.describe Resources::Forwardable do
  let(:test_class) do
    Class.new do
      extend Resources::Initializer
      extend Resources::Forwardable

      param :array
      forward :compact, :shuffle, :select, :map, to: :array
    end
  end

  let(:instance) { test_class.new([1, nil, 2, nil, 3]) }

  describe '.forward' do
    it 'forwards methods to the specified object and wraps the result' do
      expect(instance.compact).to be_a(test_class)
      expect(instance.compact.array).to eq([1, 2, 3])
    end

    it 'returns a new instance with updated array' do
      new_instance = instance.compact
      expect(new_instance).to be_a(test_class)
      expect(new_instance).not_to eq(instance)
      expect(new_instance.array).to eq([1, 2, 3])
    end

    it 'handles methods that return a new array' do
      shuffled = instance.shuffle
      expect(shuffled).to be_a(test_class)
      expect(shuffled.array).to match_array([1, nil, 2, nil, 3])
      expect(shuffled.array).not_to eq(instance.array)
    end

    it 'handles methods with blocks' do
      selected = instance.select { |x| x.is_a?(Integer) }
      expect(selected).to be_a(test_class)
      expect(selected.array).to eq([1, 2, 3])
    end

    it 'handles chained methods' do
      result = instance.compact.shuffle.select { |x| x.odd? }
      expect(result).to be_a(test_class)
      expect(result.array).to match_array([1, 3])
    end

    it 'preserves the original instance' do
      instance.compact
      expect(instance.array).to eq([1, nil, 2, nil, 3])
    end
  end
end
