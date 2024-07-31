module Resources
  module DataService
    module Associations
      class BelongsTo < Resources::Associations::BelongsTo
        def call(target: self.target)
          target.where({ id: source.pluck(source_key) })
        end

        def join_keys = { target_key => source_key }
      end
    end
  end
end
