# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module Associations
          module Entities
            module AssociationConfig
              module Base
                class Entity < Dry::Struct
                  attribute :name, Types::Symbol
                  attribute :type, Types::Symbol.enum(:belongs_to, :has_many, :has_one)

                  attribute? :conditions, Types::Any.optional
                  attribute? :association_scope, Types::Any
                end

                module Shared
                  extend ActiveSupport::Concern

                  included do
                    attributes_from Entity
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
