module Resources
  module Sql
    module Associations
      class BelongsTo < ::Resources::Associations::BelongsTo
        include Associations::Core

        # @api public
        def call(target: self.target)
          relation = target.join(source_table, join_keys)

          if view
            apply_view(schema, relation)
          else
            schema.call(relation)
          end
        end

        # @api public
        def join(type, source = self.source, target = self.target)
          source.__send__(type, target.name.dataset, join_keys).qualified
        end
      end
    end
  end
end
