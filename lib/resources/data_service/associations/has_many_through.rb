module Resources
  module DataService
    module Associations
      class HasManyThrough < Resources::Associations::HasManyThrough
        def call
          source.send(through.through_assoc_name).send(through.target_assoc_name)
        end

        def join(type, source = self.source)
          source.join_by_type(type, through.through_assoc_name => through.target_assoc_name)
        end

        def join_keys
          [through_identifier.join_association.join_keys, through_identifier.target_association.join_keys]
        end

        def source_key
          :id
        end
      end
    end
  end
end
