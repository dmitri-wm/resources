# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    class Dataset
      module Operations
        # ArySqlJoin module provides functionality to perform SQL joins with array data
        module ArySqlJoin
          module_function

          # Performs a SQL join between a left dataset and an array of data
          #
          # @param left [ActiveRecord::Relation] The left side of the join
          # @param right [Array, #to_a] The right side of the join (will be converted to array)
          # @param join_keys [Hash] A hash mapping left keys to right keys for the join condition
          # @param type [Symbol] The type of join to perform (:inner, :left, :right, :full)
          # @return [ActiveRecord::Relation] The resulting joined relation
          #
          # @example Joining users with an array of roles
          #   users = User.all
          #   roles = [{ id: 1, name: 'admin' }, { id: 2, name: 'user' }]
          #   result = ArySqlJoin.call(
          #     left: users,
          #     right: roles,
          #     join_keys: { role_id: :id },
          #     type: :left
          #   )
          #  # The resulting SQL query would be similar to:
          #  # SELECT users.*
          #  # FROM users
          #  # LEFT OUTER JOIN (
          #  #   SELECT id, name
          #  #   FROM (VALUES (1, 'admin'), (2, 'user')) AS t(id, name)
          #  # ) AS roles ON users.role_id = roles.id
          def call(left:, right:, join_keys:, type:)
            array = right.to_a
            return left.none if array.empty?

            subquery = build_subquery(array)
            alias_name = generate_unique_alias(right)
            join_cond = build_join_condition(left, join_keys, alias_name)
            perform_join(left, subquery, join_cond, type, alias_name)
          end

          private

          # Builds a SQL subquery from an array of data
          #
          # @param array [Array<Hash>] An array of hashes representing the data
          # @return [String] A SQL subquery string
          #
          # @example Building a subquery from an array of roles
          #   roles = [{ id: 1, name: 'admin' }, { id: 2, name: 'user' }]
          #   subquery = build_subquery(roles)
          #   # => "SELECT id, name FROM (VALUES (1, 'admin'), (2, 'user')) AS t(id, name)"
          def build_subquery(array)
            columns = extract_columns(array)
            values = extract_values(array)
            "SELECT #{columns} FROM (VALUES #{values}) AS t(#{columns})"
          end

          # Extracts and formats column names from the first item in the array
          #
          # @param array [Array<Hash>] An array of hashes representing the data
          # @return [String] A comma-separated string of quoted column names
          #
          # @example Extracting columns from an array of roles
          #   roles = [{ id: 1, name: 'admin' }, { id: 2, name: 'user' }]
          #   columns = extract_columns(roles)
          #   # => "\"id\", \"name\""
          def extract_columns(array)
            array.first.keys.map { |column| quote_column_name(column) }.join(', ')
          end

          # Extracts and formats values from all items in the array
          #
          # @param array [Array<Hash>] An array of hashes representing the data
          # @return [String] A comma-separated string of value tuples
          #
          # @example Extracting values from an array of roles
          #   roles = [{ id: 1, name: 'admin' }, { id: 2, name: 'user' }]
          #   values = extract_values(roles)
          #   # => "(1, 'admin'), (2, 'user')"
          def extract_values(array)
            array.map { |item| "(#{item.values.map { |value| quote(value) }.join(", ")})" }.join(', ')
          end

          # Generates a unique alias for the subquery
          #
          # @param dataset [#respond_to?(:relation_name)] The dataset to generate an alias for
          # @return [String] A unique alias string
          #
          # @example Generating an alias for a dataset
          #   dataset = User.all
          #   alias_name = generate_unique_alias(dataset)
          #   # => "users"
          def generate_unique_alias(dataset)
            dataset.respond_to?(:relation_name) ? dataset.relation_name : "subquery_#{dataset.hash.abs.to_s(36)}"
          end

          # Builds the join condition based on the provided join keys
          #
          # @param left [ActiveRecord::Relation] The left side of the join
          # @param join_keys [Hash] A hash mapping left keys to right keys
          # @param alias_name [String] The alias for the right side of the join
          # @return [String] The join condition as a SQL string
          #
          # @example Building a join condition
          #   left = User.all
          #   join_keys = { role_id: :id }
          #   alias_name = 'roles'
          #   condition = build_join_condition(left, join_keys, alias_name)
          #   # => "users.role_id = roles.id"
          def build_join_condition(left, join_keys, alias_name)
            join_keys.map { |left_key, right_key| "#{left.table_name}.#{left_key} = #{alias_name}.#{right_key}" }.join(' AND ')
          end

          # Performs the actual join operation
          #
          # @param left [ActiveRecord::Relation] The left side of the join
          # @param subquery [String] The subquery representing the right side of the join
          # @param join_cond [String] The join condition
          # @param type [Symbol] The type of join to perform
          # @param alias_name [String] The alias for the right side of the join
          # @return [ActiveRecord::Relation] The resulting joined relation
          #
          # @example Performing a left join
          #   left = User.all
          #   subquery = "SELECT id, name FROM (VALUES (1, 'admin'), (2, 'user')) AS t(id, name)"
          #   join_cond = "users.role_id = roles.id"
          #   result = perform_join(left, subquery, join_cond, :left, 'roles')
          def perform_join(left, subquery, join_cond, type, alias_name)
            join_type = get_join_type(type)
            left.joins("#{join_type} (#{subquery}) AS #{alias_name} ON #{join_cond}")
          end

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

          # Quotes a column name for use in SQL
          #
          # @param column [String, Symbol] The column name to quote
          # @return [String] The quoted column name
          #
          # @example Quoting a column name
          #   quoted_name = quote_column_name(:user_id)
          #   # => "\"user_id\""
          def quote_column_name(column)
            ActiveRecord::Base.connection.quote_column_name(column)
          end

          # Quotes a value for use in SQL
          #
          # @param value [Object] The value to quote
          # @return [String] The quoted value
          #
          # @example Quoting a string value
          #   quoted_value = quote('admin')
          #   # => "'admin'"
          def quote(value)
            ActiveRecord::Base.connection.quote(value)
          end
        end
      end
    end
  end
end
