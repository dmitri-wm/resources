# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module Associations
          module Entities
            module AssociationConfig
              module_function

              def new(**arguments)
                case arguments
                in through: Symbol, source: Symbol
                  ThroughRelation.new(arguments)
                in type: :belongs_to
                  BelongsTo.new(arguments)
                in type: :has_many
                  HasMany.new(arguments)
                in type: :has_one
                  HasOne.new(arguments)
                else
                  raise ArgumentError, "Unknown association type: #{arguments[:type]}"
                end
              end
            end
          end
        end
      end
    end
  end
end
