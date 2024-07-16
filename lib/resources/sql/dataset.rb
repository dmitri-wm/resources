# frozen_string_literal: true

# domain: Change Events

module Resources
  module Sql
    class Dataset
      include Forwardable
      extend Dry::Initializer

      # @!attribute DB query
      param :query

      forward :where, :select, :join, :order, to: :query
    end
  end
end
