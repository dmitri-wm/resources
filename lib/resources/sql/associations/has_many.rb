# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      # HasMany class represents a has-many association in SQL
      class HasMany < Resources::Associations::HasMany
        include Associations::Core

        # Executes the has-many association
        #
        # @param target [Resources::Relation] The target relation (default: self.target)
        # @return [Resources::Relation] The joined relation with view applied if defined
        def call(target: self.target)
          target.join(relation: source, join_keys: { target_key => source_key }, name: singular_source_name).then(&method(:maybe_apply_view))
        end

        # Performs a join operation
        #
        # @param type [Symbol] The type of join to perform (:join, :left_outer_join, :inner_join)
        # @param source [Resources::Relation] The source relation (default: self.source)
        # @param target [Resources::Relation] The target relation (default: self.target)
        # @return [Resources::Relation] The joined relation
        def join(type, source = self.source, target = self.target)
          source.join(relation: target, join_keys:, type:, name:)
        end
      end
    end
  end
end
