# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe Resources::Relation::Graph do
  let(:associations) { double('Associations') }
  let(:relation) { double('Relation', relation_name: :parent, associations: associations) }
  let(:comments_relation) { double('CommentsRelation', associations: associations, relation_name: :comments) }
  let(:users_relation) { double('UsersRelation', associations: associations, relation_name: :users) }
  let(:posts_relation) { double('PostsRelation', associations: associations, relation_name: :posts) }
  let(:graph) { described_class.new(relation: relation) }

  let(:comments_association) { double('Association', target: comments_relation, join_keys: { post_id: :id }, result: :one) }
  let(:users_association) { double('Association', target: users_relation, join_keys: { user_id: :id }, result: :many) }
  let(:posts_association) { double('Association', target: posts_relation, join_keys: { user_id: :id }, result: :many) }

  before do
    allow(associations).to receive(:[]).with(:comments).and_return(comments_association)
    allow(associations).to receive(:[]).with(:users).and_return(users_association)
    allow(associations).to receive(:[]).with(:posts).and_return(posts_association)
  end

  describe '#join' do
    let(:association) { double('Association', target: :comments, join_keys: { post_id: :id }) }

    it 'builds a node with the given relation and join keys' do
      result = graph.join(comments_relation, { post_id: :id }, type: :left)
      expect(result).to be_a(described_class)
      expect(result.nodes.first).to eq(
        described_class.new(
          relation: comments_relation,
          meta: { join_keys: { post_id: :id }, join_type: :left, name: :comments }
        ).to_ast
      )
    end
  end

  describe '#joins' do
    it 'builds nodes from the given schema' do
      result = graph.joins(:comments, users: :posts)
      expect(result.nodes).to eq([
                                   described_class.new(
                                     relation: comments_relation,
                                     meta: {
                                       join_keys: comments_association.join_keys,
                                       join_type: :inner,
                                       result: comments_association.result,
                                       name: :comments
                                     }
                                   ).to_ast,
                                   described_class.new(
                                     relation: users_relation,
                                     meta: {
                                       join_keys: users_association.join_keys,
                                       join_type: :inner,
                                       result: users_association.result,
                                       name: :users
                                     },
                                     nodes: [
                                       described_class.new(
                                         relation: posts_relation,
                                         meta: {
                                           join_keys: posts_association.join_keys,
                                           join_type: :inner,
                                           result: posts_association.result,
                                           name: :posts
                                         }
                                       ).to_ast
                                     ]
                                   ).to_ast
                                 ])
    end

    it 'handles different join types' do
      result = graph.left_outer_join(:comments, users: :posts)
      result.visualize
      expect(result.nodes).to eq([
                                   described_class.new(
                                     relation: comments_relation,
                                     meta: {
                                       join_keys: comments_association.join_keys,
                                       join_type: :left,
                                       result: comments_association.result,
                                       name: :comments
                                     }
                                   ).to_ast,
                                   described_class.new(
                                     relation: users_relation,
                                     meta: {
                                       join_keys: users_association.join_keys,
                                       join_type: :left,
                                       result: users_association.result,
                                       name: :users
                                     },
                                     nodes: [
                                       described_class.new(
                                         relation: posts_relation,
                                         meta: {
                                           join_keys: posts_association.join_keys,
                                           join_type: :left,
                                           result: posts_association.result,
                                           name: :posts
                                         }
                                       ).to_ast
                                     ]
                                   ).to_ast
                                 ])
    end

    it 'handles more complex nested structures' do
      result = graph.joins(:comments, users: :posts)
      result = result.joins(users: { posts: :comments })
      result.visualize
      expect(result.nodes)
        .to eq([
                 described_class.new(
                   relation: comments_relation,
                   meta: {
                     join_keys: comments_association.join_keys,
                     join_type: :inner,
                     result: comments_association.result,
                     name: :comments
                   }
                 ).to_ast,
                 described_class.new(
                   relation: users_relation,
                   meta: {
                     join_keys: users_association.join_keys,
                     join_type: :inner,
                     result: users_association.result,
                     name: :users
                   },
                   nodes: [
                     described_class.new(
                       relation: posts_relation,
                       meta: {
                         join_keys: posts_association.join_keys,
                         join_type: :inner,
                         result: posts_association.result,
                         name: :posts
                       },
                       nodes: [
                         described_class.new(
                           relation: comments_relation,
                           meta: {
                             join_keys: comments_association.join_keys,
                             join_type: :inner,
                             result: comments_association.result,
                             name: :comments
                           }
                         ).to_ast
                       ]
                     ).to_ast
                   ]
                 ).to_ast
               ])
    end
  end

  describe '#fetch_association' do
    let(:comments_association) { double('Association') }

    before do
      allow(associations).to receive(:[]).with(:comments).and_return(comments_association)
      allow(associations).to receive(:[]).with(:non_existent).and_return(nil)
    end

    it 'returns the association if it exists' do
      expect(graph.fetch_association(:comments)).to eq(comments_association)
    end

    it 'raises an error if the association does not exist' do
      expect { graph.fetch_association(:non_existent) }.to raise_error('Association non_existent not found')
    end
  end

  describe '#fetch_node' do
    before do
      graph.instance_variable_set(:@nodes, [[comments_relation, {}], [users_relation, {}], [posts_relation, {}]])
    end

    it 'returns the node if it exists' do
      expect(graph.fetch_node(posts_relation)).to eq({})
    end

    it 'returns nil if the node does not exist' do
      expect(graph.fetch_node(:non_existent)).to be_nil
    end
  end

  describe '#fetch_node!' do
    before do
      graph.instance_variable_set(:@nodes, [[comments_relation, {}], [users_relation, {}], [posts_relation, {}]])
    end

    it 'returns the node if it exists' do
      expect(graph.fetch_node!(posts_relation)).to eq({})
    end

    it 'raises an error if the node does not exist' do
      expect { graph.fetch_node!(:non_existent) }.to raise_error('Node non_existent not found')
    end
  end

  describe '#where' do
    it 'applies simple conditions to the graph' do
      conditions = { active: true }
      filtered_graph = graph.where(conditions)

      expect(filtered_graph).to be_a(described_class)
      expect(filtered_graph.filters).to include(conditions)
      expect(filtered_graph).not_to eq(graph)
    end

    it 'handles multiple conditions' do
      conditions = { active: true, status: 'pending' }
      filtered_graph = graph.where(conditions)

      expect(filtered_graph.filters).to include(conditions)
    end

    it 'handles nested conditions for associations' do
      filtered_graph = graph.joins(users: { posts: :comments }).where(status: :draft, users: { active: true })
      filtered_graph = filtered_graph.where(status: :draft,  users: { posts: { published_at: Date.today } })
      filtered_graph = filtered_graph.where(status: :draft,  users: { posts: { comments: { liked: true } } })
      filtered_graph.visualize
      expect(filtered_graph.nodes).not_to be_empty
      users_node = filtered_graph.fetch_node!(:users)
      expect(users_node.filters).to include(active: true)
    end

    it 'combines multiple where calls' do
      first_filter = graph.where(active: true)
      second_filter = first_filter.where(status: 'pending')

      expect(second_filter.filters).to match_array([{ active: true }, { status: 'pending' }])
    end
  end

  describe '#call' do
    it 'calls join_nested with the relation' do
      expect(graph).to receive(:join_nested).with(relation)
      graph.call
    end
  end
end
