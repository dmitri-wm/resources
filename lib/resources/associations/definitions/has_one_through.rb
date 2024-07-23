# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      class HasOneThrough < HasManyThrough
        result :one
      end
    end
  end
end
