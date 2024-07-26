require_relative '../../spec_helper'

RSpec.describe Graph do
  let(:relation) { double('Relation') }
  let(:nested_relation_visitor) { NestedRelationVisitor.new }

  before do
    allow(relation).to receive(:join).and_return(relation)
    allow(relation).to receive(:where).and_return(relation)
  end

  describe '#join' do
    it 'joins a relation with given join keys' do
      graph = Graph.new(relation: relation)
      joined_graph = graph.join(:some_relation, join_keys: { id: :relation_id })

      expect(joined_graph.nodes.size).to eq(1)
      expect(joined_graph.nodes.first.relation).to eq(:some_relation)
      expect(joined_graph.nodes.first.join_keys).to eq({ id: :relation_id })
    end
  end

  describe '#joins' do
    it 'joins multiple relations' do
      graph = Graph.new(relation: relation)
      joined_graph = graph.joins(:relation1, relation2: { join_keys: { id: :relation2_id } })

      expect(joined_graph.nodes.size).to eq(2)
      expect(joined_graph.nodes.first.relation).to eq(:relation1)
      expect(joined_graph.nodes.last.relation).to eq(:relation2)
      expect(joined_graph.nodes.last.join_keys).to eq({ id: :relation2_id })
    end
  end

  describe '#where' do
    it 'applies where conditions to the graph' do
      graph = Graph.new(relation: relation)
      filtered_graph = graph.where(name: 'Test')

      expect(filtered_graph.filters).to eq({ name: 'Test' })
    end
  end

  describe '#call' do
    it 'executes the graph query' do
      graph = Graph.new(relation: relation)
      expect(graph).to receive(:join_nested).with(relation)

      graph.call
    end
  end

  describe '#join_nested' do
    it 'joins nested relations' do
      node1 = Graph.new(relation: :relation1)
      node2 = Graph.new(relation: :relation2)
      graph = Graph.new(relation: relation, nodes: [node1, node2])

      expect(graph).to receive(:efficient_join).with(relation, node1).and_return(relation)
      expect(graph).to receive(:efficient_join).with(relation, node2).and_return(relation)

      graph.send(:join_nested, relation)
    end
  end
end
