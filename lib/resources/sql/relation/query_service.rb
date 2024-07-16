# frozen_string_literal: true

# domain: Change Events

module Resources
  module Relation
    # This module provides a way to use a filter service in the adapter.
    # It allows setting a filter service for the class and a custom filter service for a specific instance.
    # The filter service can be a class or a proc that accepts a single argument and returns the filtered data.
    class QueryService < ::Resources::Relation
      extend Concern

      defines :service

      option :filters

      dataset { Dataset.new(base_query) }

      def base_query
        service.call(context)
      end
    end
  end
end
