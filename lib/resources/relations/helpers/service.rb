# frozen_string_literal: true

# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Helpers
        module Service
          module_function

          def execute(service:, data:, context:)
            { service:, data:, context: }.then do |args|
              if service.respond_to?(:call)
                call_service(**args)
              elsif service.respond_to?(:to_proc)
                service.to_proc.call(data)
              elsif service.respond_to?(:new)
                initialize_service(**args).then(&method(:try_to_call))
              else
                raise ArgumentError, 'Invalid service: '
              end
            end
          end

          def initialize_service(**kwargs)
            call_with_parameters(method: :new, **kwargs)
          end

          def call_service(**kwargs)
            call_with_parameters(method: :call, **kwargs)
          end

          def call_with_parameters(service:, method:, data:, context:)
            parameters = service.method(method).parameters
            case parameters
            when [%i[req data]] || [%i[opt data]]
              service.send(method, data)
            when [%i[keyreq data]] || [%i[key data]]
              service.send(method, data:)
            when [%i[keyreq data], %i[keyreq context]] || [%i[key data], %i[key context]]
              service.send(method, data:, context:)
            when [[:rest]]
              service.send(method, data, context)
            else
              raise ArgumentError, "Unsupported service proc signature: #{service_proc}"
            end
          end

          def try_to_call(service_instance)
            service.respond_to?(:call) ? service_instance.call : service_instance
          end
        end
      end
    end
  end
end
