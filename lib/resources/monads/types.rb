# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Monads
          module Types
            include Dry.Types

            Callable = Types.Interface(:call)

            module Inherited
              def self.from(klass)
                Types::Instance(Class).constrained(lt: klass)
              end
            end
          end
        end
      end
    end
  end
end
