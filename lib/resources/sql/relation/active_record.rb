# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      class ActiveRecord < Resources::Relation
        adapter :sql

        relation_name :active_record

        class << self
          attr_accessor :ar_model, :context_columns

          def use_ar_model(model)
            self.ar_model = model
            self.context_columns = ar_model.column_names.map(&:to_sym) & %i[company_id project_id]
          end
        end
        delegate :ar_model, :context_columns, to: :class

        option :dataset, default: -> { Dataset.new(base_query) }

        # methods which changes dataset or produces new dataset collection should be forwarderd
        forward(*Dataset::QUERY_METHODS, to: :dataset)
        # methods which fetch single resource or collection of resources from datasource
        # should be loaded on dataset it will be transformed to resource or collection relations
        load_on :find, :find_by, :take, :find_sole_by, :first, :last

        # other methods which returns number / boolean / nill / array of numbers / booleans
        # should be loaded on dataset and returned without loading relation collections
        delegate :exists?, :any?, :many?, :none?, :one?, :count, :average, :minimum, :maximum, :sum, :calculate, to: :dataset

        def context_conditions
          {
            company_id: context.company_id,
            project_id: context.project_id
          }.slice(*context_columns)
        end

        def base_query
          ar_model.where(context_conditions)
        end
      end
    end
  end
end
