# frozen_string_literal: true

module Resources
  class Relation
    module Materializable
      def to_a
        call.to_a
      end
      alias to_ary to_a

      def each(&block)
        return to_enum unless block_given?

        to_a.each(&block)
      end

      def all
        fetch.then(&to_view)
      end

      def first
        paginate(page: 1, per_page: 1).then(&one)
      end

      def pluck(*args)
        call.then(&to_pluckable).pluck(*args)
      end

      def to_pluckable
        ->(data) { data.respond_to?(:pluck) ? data : to_array(data) }
      end

      def one
        call.one
      end

      def one!
        call.one!
      end
    end
  end
end
