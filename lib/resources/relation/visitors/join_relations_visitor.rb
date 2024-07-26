module Resources
  module Relation
    module Visitors
      class JoinRelationsVisitor
        def visit(graph, relation, type)
          case relation
          when Symbol
            graph.join(relation: relation, type: type)
          when Hash
            visit_hash(graph, relation, type)
          else
            raise ArgumentError, "Unsupported argument type for joins: #{relation.class}"
          end
        end

        private

        def visit_hash(graph, relations, type)
          relations.reduce(graph) do |acc, (relation, nested_relations)|
            new_node = acc.join_relation(relation, nested_relations, type)
            nested_relations.is_a?(Hash) && !nested_relations.empty? ? new_node.nodes.last.joins(nested_relations) : new_node
          end
        end
      end
    end
  end
end
