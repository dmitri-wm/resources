# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module SelectableFields
          attr_accessor :fields_to_select

          def update_fields_to_select(fields)
            case fields
            when Array
              fetch_fields_to_select.contact(fields)
            when String
              fetch_fields_to_select << fields
            else
              raise ArgumentError, 'Invalid fields argument. Must be a string or an array of strings'
            end
          end
          alias_method :select, :update_fields_to_select

          def fetch_fields_to_select
            Maybe(fields_to_select.presence).value_or(set_default)
          end

          def set_default
            self.fields_to_select = []
          end

          def select_fields(_data)
            raise 'Not implemented'
          end
        end
      end
    end
  end
end
