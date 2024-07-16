# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      class ActiveRecord < Resources::Relation
        class << self
          attr_accessor :ar_model, :context_columns

          def use_ar_model(model)
            self.ar_model = model
            self.context_columns = ar_model.column_names.map(&:to_sym) & %i[company_id project_id]
          end
        end
        def_delegators :class, :ar_model, :context_columns

        dataset { Dataset.call(base_query) }

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
