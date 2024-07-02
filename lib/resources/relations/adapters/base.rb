# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      class Base
        include Lib::Dependencies
        include Lib::UseSortingService
        include Lib::UseEntityMapper
        include Lib::WhereQueries
        include Lib::Pagination
        include Lib::SelectableFields
        include Lib::ArrayConversion
        include Lib::Transformation
        include Lib::Associations

        use_sorting_service ->(*_) { raise 'You need to setup sorting service' }
        default_entity_mapper Resources::Entities::Auto

        def initialize(context:)
          @context = context
        end

        delegate :project_id, :company_id, to: :context
        attr_reader :context

        def all
          fetch.then(&to_view)
        end

        def one
          paginate(page: 1, per_page: 1).then(&method(:all)).first
        end

        def pluck(*args)
          fetch.then(&to_pluckable).pluck(*args)
        end

        # @description this method should contain logic for fetching and transforming data
        # @example
        #   def fetch
        #     base_query.
        #     then(&method(:apply_filters))
        #     then(&method(:apply_where)).
        #     then(&method(:select_fields)).
        #     then(&method(:sort_data)).
        #     then(&method(:paginate_data))
        #   end
        # @return [Array]
        def fetch
          raise NotImplementedError, "Subclass #{self.class.name} must implement #fetch"
        end
      end
    end
  end
end
