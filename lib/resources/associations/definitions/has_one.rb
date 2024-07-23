# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      # Defines a has_one association
      class HasOne < Abstract
        result :one

        # Example:
        # class User
        #   has_one :profile
        # end
      end
    end
  end
end
