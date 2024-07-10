# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        # This module provides a way to use a filter service in the adapter.
        # It allows setting a filter service for the class and a custom filter service for a specific instance.
        # The filter service can be a class or a proc that accepts a single argument and returns the filtered data.
        module UseFiltersService
          extend ActiveSupport::Concern

          attr_accessor :filters

          included do
            # Returns the filter service for the class.
            #
            # @return [Class, Proc, nil] The filter service or nil if not set.
            class << self
              attr_accessor :filters_service
            end
          end

          class_methods do
            # Sets the filter service for the class.
            #
            # @param service [Class, Proc] The filter service to use. It can be a class or a proc.
            # @example
            #   class Adapter
            #     include Lib::UseFiltersService
            #     use_filters_service MyFilterService
            #   end
            # @example
            #   class Adapter
            #     include Lib::UseFiltersService
            #     use_filters_service ->(data) { data.where(active: true) }
            #   end
            def use_filters_service(service)
              self.filters_service = service
            end
          end

          def filters_service
            self.class.filters_service
          end

          def filter(args={})
            tap do
              filters.presence ? update_filters(args) : setup_filters!(args)
            end
          end

          # Updates the filters with the given parameters.
          #
          # @param args [Hash] The filters to update.
          # @return [self]
          def update_filters(args={})
            tap { filters.merge!(args) }
          end

          def setup_filters!(filters={})
            tap do |instance|
              instance.filters = filters
            end
          end

          def using_filters_service?
            filters_service.present?
          end

          def call_filters_service
            filters_service.call(context: context, filters: filters).query
          end
        end
      end
    end
  end
end
