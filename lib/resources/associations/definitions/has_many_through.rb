# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      class HasManyThrough < Abstract
        result :many

        option :through, reader: true

        # @api private
        def through_relation
          through.relation
        end

        # @api private
        def through_assoc_name
          through.assoc_name
        end
      end
    end
  end
end
