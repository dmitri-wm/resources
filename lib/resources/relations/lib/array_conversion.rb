# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module ArrayConversion
          def to_array(collection)
            collection.is_a?(::WillPaginate::Collection) ? collection : collection.to_a
          end

          def to_pluckable
            ->(data) { data.respond_to?(:pluck) ? data : to_array(data) }
          end
        end
      end
    end
  end
end
