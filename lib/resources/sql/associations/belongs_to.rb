# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      # BelongsTo class represents a belongs-to association in SQL
      class BelongsTo < ::Resources::Associations::BelongsTo
        include Associations::Core

        # Executes the belongs-to association
        #
        # @param target [Resources::Relation] The target relation (default: self.target)
        # @return [Resources::Relation] The joined relation
        def call(target: self.target)
          target.join(
            relation: source,
            join_keys: { target_key => source_key },
            name: source.relation_name.to_s.pluralize.to_sym
          ).distinct
        end

        # Performs a join operation
        #
        # @param type [Symbol] The type of join to perform
        # @param source [Resources::Relation] The source relation (default: self.source)
        # @param target [Resources::Relation] The target relation (default: self.target)
        # @return [Resources::Relation, Resources::Relation::Graph] The joined relation
        def join(type, source = self.source, target = self.target)
          source.join(
            relation: target,
            join_keys: { source_key => target_key },
            type:,
            name:
          )
        end
      end
    end
  end
end
