# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      class HasManyThrough < Resources::Associations::HasManyThrough
        include Associations::Core

        def call(target: self.target)
          source.send(through.through_assoc_name).send(through.target_assoc_name)
        end

        def join(type, source = self.source)
          through_association = source.associations[through.through_assoc_name]
          through_relation = through_association.target
          source = source.join(relation: through_relation, join_keys: through_association.join_keys, type:)

          target_association = through_relation.associations[through.target_assoc_name]
          source.join(relation: target_association.target, join_keys: target_association.join_keys, type:)
        end

        # through_assoc = source.associations[through]
        #
        # # first we join source to intermediary
        # joined = through_assoc.join(type, source)
        #
        # # then we join intermediary to target
        # target_ds  = target.name.dataset
        # through_jk = through_assoc.target.associations[target_ds].join_keys
        # joined.__send__(type, target_ds, through_jk).qualified

        def join_keys
          { source_key => target_key }
        end

        memoize :join_keys
      end
    end
  end
end
