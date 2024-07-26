module Resources
  module Relation
    module Visitors
      class Graph
        def visit(graph, relation, type)
          raise NotImplementedError
        end
      end
    end
  end
end
