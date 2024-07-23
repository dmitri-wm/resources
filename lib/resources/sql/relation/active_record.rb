# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      # ActiveRecord class provides an ActiveRecord-based implementation of the SQL Relation
      class ActiveRecord < Resources::Relation
        adapter :sql

        relation_name :active_record

        class << self
          # @!attribute [rw] ar_model
          #   @return [Class] The ActiveRecord model class
          # @!attribute [rw] context_columns
          #   @return [Array<Symbol>] The context-specific columns
          attr_accessor :ar_model, :context_columns

          # Sets the ActiveRecord model to be used by this relation
          #
          # @param model [Class] The ActiveRecord model class
          # @return [void]
          #
          # @example Set User model as the AR model
          #   use_ar_model User
          def use_ar_model(model)
            self.ar_model = model
            self.context_columns = ar_model.column_names.map(&:to_sym) & %i[company_id project_id]
          end
        end
        delegate :ar_model, :context_columns, to: :class

        # @!attribute [r] dataset
        #   @return [Dataset] The dataset representing the query result
        option :dataset, default: -> { Dataset.new(base_query) }

        # Forward query methods to the dataset
        forward(*Dataset::QUERY_METHODS, to: :dataset)

        # Load specific methods on the dataset
        load_on :find, :find_by, :take, :find_sole_by, :first, :last

        # Delegate methods to the dataset
        delegate :exists?, :any?, :many?, :none?, :one?, :count, :average, :minimum, :maximum, :sum, :calculate, to: :dataset

        # Returns context-based conditions for querying
        #
        # @return [Hash] A hash of context conditions
        def context_conditions
          {
            company_id: context.company_id,
            project_id: context.project_id
          }.slice(*context_columns)
        end

        # Returns the base ActiveRecord query with context conditions applied
        #
        # @return [ActiveRecord::Relation] The base query
        def base_query
          ar_model.where(context_conditions)
        end
      end
    end
  end
end
