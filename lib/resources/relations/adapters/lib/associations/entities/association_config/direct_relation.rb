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
                    class DirectRelation < Dry::Struct
                      include Base::Shared

                      Interface = Types.Interface(:foreign_key, :primary_key, :name, :type)

                      attribute :foreign_key, Types::Symbol.optional
                      attribute :primary_key, Types::Symbol.default(:id)
                      attribute :relation, Types::Inherited.from(Adapters::Base)
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
