# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    # Dataset class for SQL-based operations
    # @api public
    class Dataset < Resources::Dataset
      adapter :active_record

      # List of query methods to be forwarded to the datasource
      DS_FORWARD_METHODS = %i[find find_by take find_sole_by first last
                              exists? any? many? none? one? find_each
                              find_in_batches in_batches select order in_order_of
                              reorder group limit offset where from and or annotate optimizer_hints extending
                              having distinct references none unscope merge except only
                              count average minimum maximum sum calculate
                              pick ids excluding without to_sql].freeze
      QUERY_METHODS = DS_FORWARD_METHODS + %i[paginate]

      forward(*DS_FORWARD_METHODS, to: :datasource)

      # @return [ActiveRecord::Relation] The underlying ActiveRecord relation
      delegate :pluck, :to_sql, :exists?, :any?, :many?, :none?, :one?, :count, :average, :minimum, :maximum, :sum, :calculate, to: :datasource

      # Executes the SQL query and returns the result as an array
      # @return [Array] The result of the SQL query
      def to_a
        connection.execute(datasource.to_sql).to_a
      end

      def paginate(page:, per_page:)
        with(datasource: datasource.offset((page - 1) * per_page).limit(per_page))
      end

      # Performs a join operation with another dataset
      # @param dataset [Dataset] The dataset to join with
      # @param join_keys [Hash] The keys to use for joining
      # @param type [Symbol] The type of join to perform (default: :inner)
      # @return [Dataset] A new dataset with the join applied
      def join(dataset:, join_keys:, type: :inner)
        case dataset.adapter
        when :active_record then Operations::ActiveRecordJoin
        else                     Operations::ArySqlJoin
        end.call(left: datasource, right: dataset.datasource, join_keys:, type:).then(&rebuild)
      end

      # @return [ActiveRecord::ConnectionAdapters::AbstractAdapter] The database connection
      def connection = ActiveRecord::Base.connection
    end
  end
end
