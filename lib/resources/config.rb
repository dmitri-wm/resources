# frozen_string_literal: true
# domain: Change Events

module Resources
  module Config
    extend ActiveSupport::Concern

    included do
      const_set(:Types, Monads::Types)
    end
  end
end
