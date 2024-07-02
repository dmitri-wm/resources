# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Relations
          module Adapters
            module Lib
              module Associations
                module Entities
                  module AssociationConfig
                    class ThroughRelation < Dry::Struct
                      include Base::Shared

                      Interface = Types.Interface(:through, :source, :name, :type)

                      attribute :through, Types::Symbol.optional
                      attribute :source, Types::Symbol.optional
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
