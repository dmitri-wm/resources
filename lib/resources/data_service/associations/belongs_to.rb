module Resources
  module DataService
    module Associations
      class BelongsTo < Resources::Associations::BelongsTo
        def call(target:)
          target.where({ id: source.pluck(source_key) })
        end
      end
    end
  end
end
