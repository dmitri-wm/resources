# frozen_string_literal: true

module Resources
  class Relation
    class Composite < Pipeline::Composite
      include Materializable

      # @return [Loaded]
      #
      # @api public
      def call(*args)
        relation = left.call(*args)
        response = right.call(relation)

        if response.is_a?(Loaded)
          response
        else
          relation.new(response)
        end
      end
      alias [] call

      # @api public
      def map_to(klass)
        self >> left.map_to(klass).mapper
      end

      private

      # @api private
      def decorate?(response)
        super || response.is_a?(Graph)
      end
    end
  end
end
