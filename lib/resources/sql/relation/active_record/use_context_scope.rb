# frozen_string_literal: true

# domain: Change Events

require 'dry/core/class_builder'

module Resources
  module Sql
    module Relation
      class ActiveRecord
        module UseContextScope
          extend Concern

          class_methods do
            def define_context_conditions(ar_model_class)
              context_columns = ar_model_class.column_names.map(&:to_sym) & %i[company_id project_id]

              class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
                 def context_conditions
                   {\n#{context_columns.map { |el| "#{el}: context.#{el}" }.join(",\n")}\n}
                 end
              RUBY
            end
          end

          # Returns the base ActiveRecord query with context conditions applied
          #
          # @return [ActiveRecord::Relation] The base query
          def context_scope
            ar_model_class.where(context_conditions)
          end
        end
      end
    end
  end
end
