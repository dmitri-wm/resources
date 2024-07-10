# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module ServiceCall
          def service_call(service:, data:)
            Adapters::Helpers::Service.execute(service: service, data: data, context: context)
          end
        end
      end
    end
  end
end
