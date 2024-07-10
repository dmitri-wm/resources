# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module Transformation
          attr_accessor :transformer_services

          def transform_with(*transformers)
            tap do
              fetch_transformers.bind(&add_transformers(transformers)).or(setup_transformers(transformers))
            end
          end

          def transform_with!(transformers)
            tap { setup_transformers(transformers) }
          end

          protected

          def add_transformers(transformers)
            ->(fetched_transformers) { fetched_transformers.concat(transformers) }
          end

          def setup_transformers(transformers)
            self.transformer_services = transformers
          end

          def fetch_transformers
            Maybe(transformer_services.presence)
          end

          def transform
            ->(data) { fetch_transformers.bind(&transform_data(data)).or(data) }
          end

          def transform_data(data)
            proc do |transformers|
              transformers.reduce(data, method(:transform_with_service))
            end
          end

          def transform_with_service(data, transformer)
            service_call(service: transformer, data: data)
          end
        end
      end
    end
  end
end
