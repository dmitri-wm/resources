module Resources
  class Relation
    module Visitors
      module GraphPathVisitor
        extend self

        def visit(graph, conditions, &)
          apply_conditions(graph, conditions, &)
        end

        private

        def apply_conditions(current_node, conditions, &block)
          return current_node if conditions.nil? || conditions.empty?

          # Separate filters for the current node and child nodes
          child_node_keys = current_node.nodes_map.keys
          child_node_params = conditions.slice(*child_node_keys)
          current_node_params = conditions.except(*child_node_keys)

          # Update current node with its filters
          updated_current_node = block.call(current_node, current_node_params)

          # Recursively apply filters to child nodes and update them
          updated_nodes = child_node_params.map do |key, value|
            apply_conditions(updated_current_node.fetch_node!(key), value, &block)
          end

          # Update the current node with the new set of nodes
          updated_current_node.with_nodes(updated_nodes)
        end
      end
    end
  end
end
