module Resources
  module Relation
    module Visitors
      class FilterRelationsVisitor
        def visit(graph, conditions)
          apply_filters(graph, conditions)
        end

        private

        def apply_filters(graph, conditions)
          conditions.each do |key, value|
            if value.is_a?(Hash) && graph.filters[key].is_a?(Hash)
              apply_filters(graph.filters[key], value)
            else
              graph.filters[key] = value
            end
          end
          graph
        end
      end
    end
  end
end
