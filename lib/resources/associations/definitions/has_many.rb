# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      # Defines a has_many association
      class HasMany < Abstract
        result :many

        # Example:
        # class Post
        #   has_many :comments
        # end
      end
    end
  end
end
