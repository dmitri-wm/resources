# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module Sql
          module UseActiveRecord
            extend ActiveSupport::Concern

            included do
              class << self
                attr_accessor :ar_model, :context_columns
              end
            end

            class_methods do
              def use_ar_model(model)
                self.ar_model = model
                self.context_columns = ar_model.column_names.map(&:to_sym) & [:company_id, :project_id]
              end
            end

            def ar_model = self.class.ar_model

            def context_columns = self.class.context_columns

            def apply_where
              ->(scope) { where_conditions.each(&update_scope(scope)) and scope }
            end

            def update_scope(scope)
              ->(condition) { scope.where!(condition) }
            end

            def initial_scope = using_filters_service? ? call_filters_service : context_scoped_ar_model

            def context_conditions
              {
                company_id: context.company_id,
                project_id: context.project_id
              }.slice(*context_columns)
            end

            def context_scoped_ar_model = ar_model.then(&scope_to_context)

            def scope_to_context =->(scope) { scope.where(context_conditions) }

            def execute_query =->(scope) { ar_model.connection.execute(scope.to_sql) }
          end
        end
      end
    end
  end
end
