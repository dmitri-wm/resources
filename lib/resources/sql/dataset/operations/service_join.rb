# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    class Dataset
      module Operations
        # ServiceJoin module provides functionality to perform SQL joins with service-based datasets
        module ServiceJoin
          extend Dry::Initializer[undefined: false]
          extend ArySqlJoin

          module_function

          # Performs a SQL join between a left dataset and a service-based right dataset
          #
          # @param left [ActiveRecord::Relation] The left side of the join
          # @param right [#to_a] The right side of the join (a service-based dataset that responds to #to_a)
          # @param join_keys [Hash] A hash mapping left keys to right keys for the join condition
          # @param relation_name [String, Symbol] The name to use for the joined relation in the SQL query
          # @param type [Symbol] The type of join to perform (default: :inner)
          # @return [ActiveRecord::Relation] The resulting joined relation
          #
          # @example Joining users with a service-based roles dataset
          #   users = User.all
          #   roles_service = RolesService.new
          #   result = ServiceJoin.call(
          #     users,
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
