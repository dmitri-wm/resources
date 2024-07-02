# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module Pagination
          def update_pagination(page:, per_page:)
            tap { pagination.merge!(page: page, per_page: per_page) }
          end
          alias_method :paginate, :update_pagination

          def pagination
            @pagination ||= {}
          end

          def paginate_data
            ->(data) { pagination.presence ? ::ApiPagination.paginate(data, pagination).first : data }
          end
        end
      end
    end
  end
end
