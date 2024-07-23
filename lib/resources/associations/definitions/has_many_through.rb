# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      # Defines a has_many association through another association
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

        # Example:
        # class Author
        #   has_many_through :comments, through: :posts
        # end
      end
    end
  end
end
