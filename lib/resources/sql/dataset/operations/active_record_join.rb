# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    class Dataset
      module Operations
        # ActiveRecordJoin module provides functionality to perform SQL joins between ActiveRecord relations
        module ActiveRecordJoin
          extend self

          # Performs a SQL join between two ActiveRecord relations
          #
          # @param left [ActiveRecord::Relation] The left side of the join
          # @param right [ActiveRecord::Relation] The right side of the join
          # @param join_keys [Hash] A hash mapping left keys to right keys for the join condition
          # @param type [Symbol] The type of join to perform (:inner, :left, :right, :full)
          # @return [ActiveRecord::Relation] The resulting joined relation
          #
          # @example Joining users with roles
          #   users = User.all
          #   roles = Role.all
          #   result = ActiveRecordJoin.call(
          #     left: users,
          #     right: roles,
          #     join_keys: { role_id: :id },
          #     type: :left
          #   )
          #
          #   # The resulting SQL query would be similar to:
          #   # SELECT users.*
          #   # FROM users
          #   # LEFT OUTER JOIN roles ON users.role_id = roles.id
          def call(left:, right:, join_keys:, type:)
            join_type = get_join_type(type)
            join_condition = build_join_condition(left, right, join_keys)

            joined_relation = left.joins("#{join_type} #{right.table_name} ON #{join_condition}")
            joined_relation.merge(right)
          end

          private

          # Determines the SQL join type based on the provided symbol
          #
          # @param type [Symbol] The type of join to perform
          # @return [String] The SQL join type
          # @raise [ArgumentError] If an unsupported join type is provided
          #
          # @example Getting the join type
          #   join_type = get_join_type(:left)
          #   # => "LEFT OUTER JOIN"
          def get_join_type(type)
            case type
            when :inner then 'INNER JOIN'
            when :left then 'LEFT OUTER JOIN'
            when :right then 'RIGHT OUTER JOIN'
            when :full then 'FULL OUTER JOIN'
            else raise ArgumentError, "Unsupported join type: #{type}"
            end
          end

          # Builds the join condition based on the provided join keys
          #
          # @param left [ActiveRecord::Relation] The left side of the join
          # @param right [ActiveRecord::Relation] The right side of the join
          # @param join_keys [Hash] A hash mapping left keys to right keys
          # @return [String] The join condition as a SQL string
          #
          # @example Building a join condition
          #   left = User.all
          #   right = Role.all
          #   join_keys = { role_id: :id }
          #   condition = build_join_condition(left, right, join_keys)
          #   # => "users.role_id = roles.id"
          def build_join_condition(left, right, join_keys)
            join_keys.map { |source_key, target_key| "#{left.table_name}.#{source_key} = #{right.table_name}.#{target_key}" }.join(' AND ')
          end
        end
      end
    end
  end
end
