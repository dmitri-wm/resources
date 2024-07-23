# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      # Defines a belongs_to association
      class BelongsTo < Abstract
        result :one

        # Example:
        # class Comment
        #   belongs_to :post
        # end
      end
    end
  end
end
