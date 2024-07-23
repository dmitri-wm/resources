# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    class Dataset < Resources::Dataset
      adapter :active_record

      QUERY_METHODS = %i[find find_by take find_sole_by first last
                         exists? any? many? none? one? find_each
                         find_in_batches in_batches select order in_order_of
                         reorder group limit offset where from and or annotate optimizer_hints extending
                         having distinct references none unscope merge except only
                         count average minimum maximum sum calculate
                         pick ids excluding without].freeze
      forward(*QUERY_METHODS, to: :datasource)

      # @!attribute [r] datasource
      delegate :pluck, :to_sql, :exists?, :any?, :many?, :none?, :one?, :count, :average, :minimum, :maximum, :sum, :calculate, to: :datasource

      def to_a
        connection.execute(datasource.to_sql).to_a
      end

      # @!param target [Relation]
      # @!param type [Symbol]
      # @!param join_keys [Hash]
      def join(dataset:, join_keys:, type: :inner)
        case dataset.adapter
        when :active_record then Operations::ActiveRecordJoin
        else                     Operations::ArySqlJoin
        end.call(left: datasource, right: dataset.datasource, join_keys:, type:).then(&rebuild)
      end

      def connection = ActiveRecord::Base.connection
    end
  end
end
