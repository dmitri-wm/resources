# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    module Relation
      def self.[](type)
        {
          AR: ActiveRecord,
          Service: QueryService
        }[type].tap do |klass|
          raise ArgumentError, "Unknown relation type: #{type}" unless klass
        end
      end
    end
  end
end
