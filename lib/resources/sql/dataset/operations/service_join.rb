# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    class Dataset
      module Operations
        module ServiceJoin
          extend Dry::Initializer[undefined: false]
          extend ArySqlJoin

          module_function

          def call(left, right, join_keys, relation_name, type = :inner)
            right.to_a.then do |array|
              return left.none if array.empty?

              subquery = [columns, fetch_values].reduce(array, :call)
              alias_name = relation_name.to_s
              join_cond = join_condition(left, join_keys, alias_name)
              join_sql(left, subquery, join_cond, type, alias_name)
            end
          end
        end
      end
    end
  end
end
