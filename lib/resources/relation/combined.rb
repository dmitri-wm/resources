module Resources
  class Relation
    class Combined < Graph
      def self.new(relation, nodes)
        new_nodes = nodes.uniq(&:name)

        root =
          if relation.is_a?(self)
            new_nodes.concat(relation.nodes)
            relation.root
          else
            relation
          end

        super(root, new_nodes)
      end

      def combine_with(*others)
        self.class.new(root, nodes + others)
      end

      def combine(*args)
        self.class.new(root, nodes + root.combine(*args).nodes)
      end

      def call(*args)
        left = root.with(auto_map: false, auto_struct: false).call(*args)

        right =
          if left.empty?
            nodes.map { |node| Loaded.new(node, EMPTY_ARRAY) }
          else
            nodes.map { |node| node.call(left) }
          end

        if auto_map?
          Loaded.new(self, mapper.call([left, right]))
        else
          Loaded.new(self, [left, right])
        end
      end

      # Return a new combined relatio
      def node(name, &block)
        if name.is_a?(Symbol) && !nodes.map { |n| n.name.key }.include?(name)
          raise ArgumentError, "#{name.inspect} is not a valid aggregate node name"
        end

        new_nodes = nodes.map do |node|
          case name
          when Symbol
            name == node.name.key ? yield(node) : node
          when Hash
            other, *rest = name.flatten(1)
            if other == node.name.key
              nodes.detect { |n| n.name.key == other }.node(*rest, &block)
            else
              node
            end
          else
            node
          end
        end

        with_nodes(new_nodes)
      end

      private

      def decorate?(other)
        super || other.is_a?(self.class) || other.is_a?(Wrap)
      end
    end
  end
end
