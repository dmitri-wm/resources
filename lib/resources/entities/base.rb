# frozen_string_literal: true
# domain: Change Events

module Resources
  module Entities
    class Base < Dry::Struct
      transform_keys(&:to_sym)
    end
  end
end
