# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      class BelongsToThrough < HasManyThrough
        result :one
      end
    end
  end
end
