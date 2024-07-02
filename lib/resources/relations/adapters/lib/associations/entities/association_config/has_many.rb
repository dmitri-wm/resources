# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module Associations
          module Entities
            module AssociationConfig
              class HasMany < Dry::Struct
                attributes_from DirectRelation
              end
            end
          end
        end
      end
    end
  end
end
