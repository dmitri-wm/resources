# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      class HasOne < HasManyThrough
        result :one
      end
    end
  end
end
