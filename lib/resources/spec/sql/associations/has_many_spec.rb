# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe Resources::Sql::Associations::HasMany do
  let(:definition) { double('definition', foreign_key: :target_id, primary_key: :source_id) }
  let(:association) { described_class.new(definition, source: source, target: target) }
  let(:source) { double('source') }
  let(:target) { double('target') }

  describe '#call' do
    it 'joins the target with the source and applies the view' do
      joined_relation = double('joined_relation')
      view_applied_relation = double('view_applied_relation')

      expect(target).to receive(:join).with(relation: source, join_keys: { target_id: :source_id }).and_return(joined_relation)
      expect(association).to receive(:maybe_apply_view).with(joined_relation).and_return(view_applied_relation)

      result = association.call
      expect(result).to eq(view_applied_relation)
    end
  end

  describe '#join' do
    it 'sends the join type to the source with target and join keys' do
      join_keys = { target_id: :source_id }
      expect(association).to receive(:join_keys).and_return(join_keys)
      expect(source).to receive(:join).with(:join_keys => { :target_id => :source_id }, :relation => target, type: :left_outer_join)

      association.join(:left_outer_join)
    end

    it 'uses default source and target if not provided' do
      join_keys = { target_id: :source_id }
      expect(association).to receive(:join_keys).and_return(join_keys)
      expect(source).to receive(:join).with(:join_keys => { :target_id => :source_id }, :relation => target, type: :inner_join)

      association.join(:inner_join)
    end

    it 'uses provided source and target' do
      custom_source = double('custom_source')
      custom_target = double('custom_target')
      join_keys = { target_id: :source_id }
      expect(association).to receive(:join_keys).and_return(join_keys)
      expect(custom_source).to receive(:join).with(:join_keys => { :target_id => :source_id }, :relation => custom_target, type: :join)

      association.join(:join, custom_source, custom_target)
    end
  end
end
