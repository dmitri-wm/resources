# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Entities
          class Auto
            def initialize(attributes={})
              attributes.each do |key, value|
                instance_variable_set("@#{key}", value)

                define_singleton_method(key) do
                  instance_variable_get("@#{key}")
                end
              end
            end
          end
        end
      end
    end
  end
end
