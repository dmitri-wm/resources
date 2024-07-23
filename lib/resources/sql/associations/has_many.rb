# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      class HasMany < Resources::Associations::HasMany
        include Associations::Core

        def call(target: self.target)
          target.join(relation: source, join_keys: { target_key => source_key }).then(&method(:maybe_apply_view))
        end

        # @param [Symbol] type in [:join, :left_outer_join, :inner_join]
        # @param [Resources::Relation] source
        # @param [Resources::Relation] target
        def join(type, source = self.source, target = self.target)
          source.join(relation: target, join_keys:, type:)
        end
      end
    end
  end
end
