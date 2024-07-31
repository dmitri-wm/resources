module Resources
  class Relation
    module Visitors
      module GraphVisitor
        extend self

        def visit(current_node, parent = nil, &block)
          current_node.instance_exec(parent, &block).then do |updated_node|
            new_nodes = current_node.nodes.filter_map do |node|
              visit(node, current_node, &block).then do |new_node|
                new_node if new_node != node
              end
            end

            updated_node.with_nodes(new_nodes)
          end
        end
      end
    end
  end
end
