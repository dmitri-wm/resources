module Resources
  module Sql
    module Associations
      class HasManyThrough < Resources::Associations::HasManyThrough
        def call(target: self.target)
          left = join_assoc.call(target:)

          relation = left.join(source_table, join_keys)

          if view
            apply_view(schema, relation)
          else
            schema.call(relation)
          end
        end

        def join(type, source = self.source, target = self.target)
          through_assoc = source.associations[through]

          # first we join source to intermediary
          joined = through_assoc.join(type, source)

          # then we join intermediary to target
          target_ds  = target.name.dataset
          through_jk = through_assoc.target.associations[target_ds].join_keys
          joined.__send__(type, target_ds, through_jk).qualified
        end

        def join_keys
          { source_key => target_key }
        end

        private

        def columns
          target_schema.map(&:name)
        end

        memoize :join_keys, :target_schema, :join_schema, :columns
      end
    end
  end
end
