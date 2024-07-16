# frozen_string_literal: true

module Resources
  class Relation
    # Abstract relation graph class
    #
    # @api public
    class Graph
      extend Dry::Initializer

      include Memoizable
      include Materializable

      include Pipeline
      include Pipeline::Proxy

      # @!attribute [r] root
      #   @return [Relation] The root relation
      param :root

      # @!attribute [r] nodes
      #   @return [Array<Relation>] An array with relation nodes
      param :nodes

      alias left root
      alias right nodes

      def with_nodes(nodes)
        self.class.new(root, nodes)
      end

      def graph?
        true
      end

      def map_with(*names, **opts)
        names.reduce(self.class.new(root.with(opts), nodes)) { |a, e| a >> mappers[e] }
      end

      def map_to(klass)
        self.class.new(root.map_to(klass), nodes)
      end

      def mapper
        mappers[to_ast]
      end

      private

      def decorate?(other)
        super || other.is_a?(Composite)
      end

      def composite_class
        Relation::Composite
      end
    end
  end
end
