# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      # Core module provides common functionality for SQL associations
      module Core
        def self.included(klass)
          super
          klass.memoize :join_keys
        end

        # Returns the join keys for the association
        #
        # @return [Hash] A hash mapping source key to target key
        def join_keys
          { source_key => target_key }
        end

        # Returns the join keys for polymorphic associations
        #
        # @return [Hash] A hash mapping foreign key and type to source key and polymorphic type
        def polymorphic_join_keys
          {
            foreign_key => source_key,
            foreign_type => polymorphic_type
          }
        end

        # Applies a view to the relation if one is defined
        #
        # @param relation [Resources::Relation] The relation to apply the view to
        # @return [Resources::Relation] The relation with the view applied, or the original relation if no view is defined
        def maybe_apply_view(relation)
          view ? apply_view(view, relation) : relation
        end
      end
    end
  end
end
