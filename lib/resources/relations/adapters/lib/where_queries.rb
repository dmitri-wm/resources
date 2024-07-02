# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module WhereQueries
          def where(*args)
            tap { where_conditions.push(*args) }
          end

          def where_conditions
            @where_conditions ||= []
          end

          def apply_where(_data)
            raise 'Need Implementation'
          end
        end
      end
    end
  end
end
