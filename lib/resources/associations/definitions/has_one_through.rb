# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      # Defines a has_one association through another association
      class HasOneThrough < HasManyThrough
        result :one

        # Example:
        # class Author
        #   has_one_through :avatar, through: :profile
        # end
      end
    end
  end
end
