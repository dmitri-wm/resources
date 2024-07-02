# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module UsePslService
          extend ActiveSupport::Concern

          included do
            mattr_accessor :psl_service
          end

          class_methods do
            def use_psl_service(service)
              self.psl_service = service
            end
          end
        end
      end
    end
  end
end
