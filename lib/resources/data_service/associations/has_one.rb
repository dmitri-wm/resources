module Resources
  module DataService
    module Associations
      class HasOne < HasMany
        # Returns the foreign key for the association
        #
        # @return [String] The foreign key name
        def foreign_key
          definition.foreign_key || "#{source.name}_id"
        end
      end
    end
  end
end
