# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      module Core
        def self.included(klass)
          super
          klass.memoize :join_keys
        end

        def join_keys
          { source_key => target_key }
        end

        def polymorphic_join_keys
          {
            foreign_key => source_key,
            foreign_type => polymorphic_type
          }
        end

        def maybe_apply_view(relation)
          view ? apply_view(view, relation) : relation
        end
      end
    end
  end
end
