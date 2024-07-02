# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module Dependencies
          extend ActiveSupport::Concern

          included do
            include Dry::Monads[:result, :maybe]
            include ServiceCall
            include Storage
          end

          # rubocop:disable Naming/MethodParameterName
          def check(condition, f:, t:)
            condition.presence ? t.call : f.call
          end
          # rubocop:enable Naming/MethodParameterName
        end
      end
    end
  end
end
