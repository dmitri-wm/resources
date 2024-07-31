# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    class Dataset
      module Operations
        # ActiveRecordJoin module provides functionality to perform SQL joins between ActiveRecord relations
        module ActiveRecordJoin
          module_function

          # Performs a SQL join between two ActiveRecord relations
          #
          # @param type [Symbol] The type of join to perform (:inner or :left)
          # @param [**] Additional keyword arguments
          # @see ActiveRecordJoin#join
          # @see ActiveRecordJoin#left_outer_join
          # @return [ActiveRecord::Relation] The resulting joined relation
          #
          # @example Joining users with roles using a left outer join
          #   users = User.all
          #   roles = Role.all
          #   result = ActiveRecordJoin.call(
          #     type: :left,
          #     left: users,
          #     right: roles,
          #     name: :role
          #   )
          #
          #   # The resulting SQL query would be similar to:
          #   # SELECT users.*
          #   # FROM users
          #   # LEFT OUTER JOIN roles ON users.role_id = roles.id
          #
          # @raise [ArgumentError] If an unsupported join type is provided
          def call(type:, **)
            case type
            when :inner then join(**)
            when :left then left_outer_join(**)
            else raise ArgumentError, "Unsupported join type: #{type}"
            end
          end

          # Performs an inner join between two ActiveRecord relations
          #
          # @param left [ActiveRecord::Relation] The left relation to join
          # @param right [ActiveRecord::Relation] The right relation to join
          # @param name [Symbol] The name of the association to join on
          # @param [**] Additional keyword arguments (unused)
          # @return [ActiveRecord::Relation] The resulting joined relation
          def join(left:, right:, name:, **)
            left.joins(name).merge(right)
          end

          # Performs a left outer join between two ActiveRecord relations
          #
          # @param left [ActiveRecord::Relation] The left relation to join
          # @param right [ActiveRecord::Relation] The right relation to join
          # @param name [Symbol] The name of the association to join on
          # @param [**] Additional keyword arguments (unused)
          # @return [ActiveRecord::Relation] The resulting joined relation
          def left_outer_join(left:, right:, name:, **)
            left.left_outer_joins(name).merge(right.or(right.unscoped.where(id: nil)))
          end
        end
      end
    end
  end
end
