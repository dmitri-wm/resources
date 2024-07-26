# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe Resources::DataService::Dataset::Loaded do
  let(:data) do
    [
      { id: 1, name: 'Alice', age: 30 },
      { id: 2, name: 'Bob', age: 25 },
      { id: 3, name: 'Charlie', age: 35 }
    ]
  end
  let(:dataset) { described_class.new(data) }

  describe '#joins_array' do
    let(:source_data) do
      [
        { user_id: 1, score: 100 },
        { user_id: 2, score: 80 },
        { user_id: 1, score: 90 }
      ]
    end
    let(:source_dataset) { described_class.new(source_data) }

    it 'performs an array-based join operation' do
      result = dataset.joins_array(dataset, source_dataset, { user_id: :id })
      expect(result.to_a).to contain_exactly(
        { id: 1, name: 'Alice', age: 30, user_id: 1, score: 100 },
        { id: 1, name: 'Alice', age: 30, user_id: 1, score: 90 },
        { id: 2, name: 'Bob', age: 25, user_id: 2, score: 80 }
      )
    end
  end

  describe '#join' do
    let(:right_data) do
      [
        { id: 1, department: 'IT' },
        { id: 2, department: 'HR' }
      ]
    end
    let(:right_dataset) { described_class.new(right_data) }

    it 'performs a join operation with another dataset' do
      result = dataset.join(right_dataset)
      expect(result.to_a).to contain_exactly(
        { id: 1, name: 'Alice', age: 30, department: 'IT' },
        { id: 2, name: 'Bob', age: 25, department: 'HR' }
      )
    end
  end

  describe '#restrict' do
    it 'filters the dataset based on criteria' do
      result = dataset.restrict(age: 30)
      expect(result).to contain_exactly({ id: 1, name: 'Alice', age: 30 })
    end

    it 'filters the dataset using a block' do
      result = dataset.restrict { |tuple| tuple[:age] > 25 }
      expect(result).to contain_exactly(
        { id: 1, name: 'Alice', age: 30 },
        { id: 3, name: 'Charlie', age: 35 }
      )
    end

    it 'handles array criteria' do
      result = dataset.restrict(age: [25, 30])
      expect(result).to contain_exactly(
        { id: 1, name: 'Alice', age: 30 },
        { id: 2, name: 'Bob', age: 25 }
      )
    end

    it 'handles regexp criteria' do
      result = dataset.restrict(name: /^A/)
      expect(result).to contain_exactly({ id: 1, name: 'Alice', age: 30 })
    end
  end

  describe '#select' do
    it 'projects the dataset to include only specified attributes' do
      result = dataset.select(:name, :age)
      expect(result).to contain_exactly(
        { name: 'Alice', age: 30 },
        { name: 'Bob', age: 25 },
        { name: 'Charlie', age: 35 }
      )
    end
  end

  describe '#order' do
    it 'orders the dataset based on a single field' do
      result = dataset.order(:age)
      expect(result.pluck(:name)).to eq(%w[Bob Alice Charlie])
    end

    it 'orders the dataset based on multiple fields' do
      data << { id: 4, name: 'David', age: 30 }
      result = dataset.order(:age, :name)
      expect(result.pluck(:name)).to eq(%w[Bob Alice David Charlie])
    end

    it 'handles descending order' do
      result = dataset.order({ age: :desc })
      expect(result.pluck(:name)).to eq(%w[Charlie Alice Bob])
    end

    context 'nils_first' do
      let(:data) do
        [
          { id: 1, name: 'Alice', age: 30, score: nil },
          { id: 2, name: 'Bob', age: nil, score: 85 },
          { id: 3, name: 'Charlie', age: 35, score: 90 },
          { id: 4, name: 'David', age: nil, score: nil },
          { id: 5, name: 'Eve', age: 28, score: 95 }
        ]
      end

      it 'orders by a single field with nils last by default' do
        result = dataset.order(:age)
        expect(result.pluck(:name)).to eq(%w[Eve Alice Charlie Bob David])
        # Sorted dataset:
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
        # { age: nil, name: 'Bob', id: 2, score: 85 },
        # { age: nil, name: 'David', id: 4, score: nil },
      end

      it 'orders by a single field with nils first when specified' do
        result = dataset.order(:age, options: { nils_first: true })
        expect(result.pluck(:name)).to eq(%w[Bob David Eve Alice Charlie])
        # Sorted dataset:
        # { age: nil, name: 'Bob', id: 2, score: 85 },
        # { age: nil, name: 'David', id: 4, score: nil },
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
      end

      it 'orders by multiple fields with nils last by default' do
        result = dataset.order(:age, :score)
        expect(result.pluck(:name)).to eq(%w[Eve Alice Charlie Bob David])
        # Sorted dataset:
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
        # { age: nil, name: 'Bob', id: 2, score: 85 },
        # { age: nil, name: 'David', id: 4, score: nil },
      end

      it 'orders by multiple fields with nils first when specified' do
        result = dataset.order(:age, :score, options: { nils_first: true })
        expect(result.pluck(:name)).to eq(%w[David Bob Eve Alice Charlie])
        # Sorted dataset:
        # { age: nil, name: 'David', id: 4, score: nil },
        # { age: nil, name: 'Bob', id: 2, score: 85 },
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
      end

      it 'handles mixed ascending and descending orders with nils last' do
        result = dataset.order(age: :asc, score: :desc)
        expect(result.pluck(:name)).to eq(%w[Eve Alice Charlie Bob David])
        # Sorted dataset:
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
        # { age: nil, name: 'Bob', id: 2, score: 85 },
        # { age: nil, name: 'David', id: 4, score: nil },
      end

      it 'handles mixed ascending and descending orders with nils first' do
        result = dataset.order({ age: :asc }, { score: :desc }, options: { nils_first: true })
        expect(result.pluck(:name)).to eq(%w[David Bob Eve Alice Charlie])
        # Sorted dataset:
        # { age: nil, name: 'David', id: 4, score: nil },
        # { age: nil, name: 'Bob', id: 2, score: 85 },
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
      end

      it 'allows overriding nils_first for specific fields' do
        result = dataset.order({ age: :asc, nils_first: false }, { score: :desc, nils_first: true })
        expect(result.pluck(:name)).to eq(%w[Eve Alice Charlie David Bob])
        # Sorted dataset:
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
        # { age: nil, name: 'David', id: 4, score: nil },
        # { age: nil, name: 'Bob', id: 2, score: 85 },
      end

      it 'prioritizes field-specific nils_first over global setting' do
        result = dataset.order({ age: :asc, nils_first: false }, { score: :desc, nils_first: true }, nils_first: true)
        expect(result.pluck(:name)).to eq(%w[Eve Alice Charlie David Bob])
        # Sorted dataset:
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
        # { age: nil, name: 'David', id: 4, score: nil },
        # { age: nil, name: 'Bob', id: 2, score: 85 },
      end

      it 'handles all nil values for a field' do
        all_nil_data = [
          { id: 1, name: 'Alice', value: nil },
          { id: 2, name: 'Bob', value: nil },
          { id: 3, name: 'Charlie', value: nil }
        ]
        all_nil_dataset = described_class.new(all_nil_data)
        result = all_nil_dataset.order(:value, :name)
        expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie])
        # Sorted dataset:
        # { id: 1, name: 'Alice', value: nil }
        # { id: 2, name: 'Bob', value: nil }
        # { id: 3, name: 'Charlie', value: nil }
      end

      it 'maintains original order for equal non-nil values' do
        equal_data = [
          { id: 1, name: 'Alice', value: 10 },
          { id: 2, name: 'Bob', value: 10 },
          { id: 3, name: 'Charlie', value: 10 }
        ]
        equal_dataset = described_class.new(equal_data)
        result = equal_dataset.order(:value)
        expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie])
        # Sorted dataset:
        # { id: 1, name: 'Alice', value: 10 }
        # { id: 2, name: 'Bob', value: 10 }
        # { id: 3, name: 'Charlie', value: 10 }
      end

      it 'handles complex nested sorting scenarios' do
        result = dataset.order(
          { age: :asc, nils_first: true },
          { score: :desc, nils_first: false },
          :name
        )
        expect(result.pluck(:name)).to eq(%w[Bob David Eve Alice Charlie])
        # Sorted dataset:
        # { age: nil, name: 'Bob', id: 2, score: 85 },
        # { age: nil, name: 'David', id: 4, score: nil },
        # { age: 28, name: 'Eve', id: 5, score: 95 }
        # { age: 28, name: 'Glen', id: 5, score: 90 }
        # { age: 30, name: 'Alice', id: 1, score: nil },
        # { age: 35, name: 'Charlie', id: 3, score: 90 },
      end

      it 'handles nested ordering' do
        nested_data = [
          { id: 1, name: 'Alice', age: 30, task: { name: 'Second Task' } },
          { id: 2, name: 'Bob', age: nil, task: { name: 'First Task' } },
          { id: 3, name: 'Charlie', age: 35, task: { name: 'Third Task' } },
          { id: 4, name: 'David', age: nil, task: { name: nil } },
          { id: 5, name: 'Eve', age: 28, task: { name: 'Fourth Task' } }
        ]
        nested_dataset = described_class.new(nested_data)

        result = nested_dataset.order('task.name': :asc, options: { nested: true })
        expect(result.pluck(:name)).to eq(%w[Bob Eve Alice Charlie David])
        # Sorted dataset:
        # { id: 2, name: 'Bob', age: nil, task: { name: 'First Task' } }
        # { id: 5, name: 'Eve', age: 28, task: { name: 'Fourth Task' } }
        # { id: 1, name: 'Alice', age: 30, task: { name: 'Second Task' } }
        # { id: 3, name: 'Charlie', age: 35, task: { name: 'Third Task' } }
        # { id: 4, name: 'David', age: nil, task: { name: nil } }
      end
    end
  end

  describe '#insert' do
    it 'inserts a tuple into the dataset' do
      dataset.insert({ id: 4, name: 'David', age: 40 })
      expect(dataset.to_a).to include({ id: 4, name: 'David', age: 40 })
    end
  end

  describe '#delete' do
    it 'deletes a tuple from the dataset' do
      tuple_to_delete = { id: 2, name: 'Bob', age: 25 }
      dataset.delete(tuple_to_delete)
      expect(dataset.to_a).not_to include(tuple_to_delete)
    end
  end

  describe 'enumerable methods' do
    it 'implements enumerable methods' do
      expect(dataset.map { |t| t[:name] }).to eq(%w[Alice Bob Charlie])
      expect(dataset.reject { |t| t[:age] < 30 }.map { |t| t[:name] }).to eq(%w[Alice Charlie])
    end
  end
end
