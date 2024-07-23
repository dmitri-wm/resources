# frozen_string_literal: true

module Resources
  class Relation
    class Loaded
      include Enumerable

      alias to_ary to_a

      attr_reader :source, :collection

      def initialize(source, collection = source.to_a)
        @source = source
        @collection = collection
      end

      def each(&block)
        return to_enum unless block_given?

        collection.each(&block)
      end

      def one
        raise('The relation consists of more than one tuple') if collection.count > 1

        collection.first
      end

      # @api public
      def one!
        one || raise('The relation does not contain any tuples')
      end

      def primary_keys
        pluck(source.primary_key)
      end

      def empty?
        collection.empty?
      end

      def new(collection)
        self.class.new(source, collection)
      end
    end
  end
end
