# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      # ActiveRecord class provides an ActiveRecord-based implementation of the SQL Relation
      class ActiveRecord < Resources::Relation
        include UseArModel
        include UseContextScope

        adapter :sql

        relation_name :active_record

        # @!attribute [r] dataset
        #   @return [Dataset] The dataset representing the query result
        option :dataset, default: -> { Dataset.new(base_query) }

        # Forward query methods to the dataset
        forward(*Dataset::QUERY_METHODS, to: :dataset)

        # Load specific methods on the dataset
        load_on :find, :find_by, :take, :find_sole_by, :first, :last

        # Delegate methods to the dataset
        delegate :exists?, :any?, :many?, :none?, :one?, :count, :average, :minimum, :maximum, :sum, :calculate, :to_sql, to: :dataset

        def join!(relation:, type:, name:, join_keys: {})
          with(dataset: dataset.join(dataset: relation.dataset, join_keys:, type:, name:))
        end

        def base_query
          context_scope
        end
      end
    end
  end
end
