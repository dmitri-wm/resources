module Resources
  module DataService
    module Associations
      class HasMany < Resources::Associations::HasMany
        def call(target: self.target)
          target.where(foreign_key.to_sym => source.pluck(:id))
        end

        def join_keys = { target_key => source_key }
      end
    end
  end
end
