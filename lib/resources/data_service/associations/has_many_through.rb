module Resources
  module DataService
    module Associations
      class HasManyThrough < Resources::Associations::HasManyThrough
        def call
          source.send(through.through_assoc_name).send(through.target_assoc_name)
        end
      end
    end
  end
end
