# frozen_string_literal: true

module Resources
  module Associations
    # Represents a has_one_through association between resources
    # This class inherits from HasManyThrough and provides specific behavior for has_one_through associations.
    # It is used to establish a one-to-one relationship between two resources through an intermediate resource.
    class HasOneThrough < HasManyThrough
      # Add HasOneThrough specific behavior here if needed
    end
  end
end
