# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      # HasManyThrough class represents a has-many-through association in SQL
      class HasManyThrough < Resources::Associations::HasManyThrough
        include Associations::Core

        # Executes the has-many-through association
        #
        # @param target [Resources::Relation] The target relation (default: self.target)
        # @return [Resources::Relation] The result of the association
        def call(target: self.target)
          source.send(through.through_assoc_name).send(through.target_assoc_name)
        end

        # Performs a join operation for the has-many-through association
        #
        # @param type [Symbol] The type of join to perform
        # @param source [Resources::Relation] The source relation (default: self.source)
        # @return [Resources::Relation] The joined relation
        def join(type, source = self.source)
          through_association = source.associations[through.through_assoc_name]
          through_relation = through_association.target
          source = source.join(relation: through_relation, join_keys: through_association.join_keys, type:)

          target_association = through_relation.associations[through.target_assoc_name]
          source.join(relation: target_association.target, join_keys: target_association.join_keys, type:)
        end

        # Returns the join keys for the association
        #
        # @return [Hash] A hash mapping source key to target key
        def join_keys
          { source_key => target_key }
        end

        memoize :join_keys
      end
    end
  end
end
