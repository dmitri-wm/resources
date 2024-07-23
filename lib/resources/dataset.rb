# frozen_string_literal: true

# domain: Change Events

module Resources
  class Dataset
    extend Forwardable
    extend Dry::Initializer
    extend Dry::Core::ClassAttributes

    # @!attribute [r] adapter
    defines :adapter, type: Types::Symbol

    adapter :default
    delegate :adapter, to: :class

    # @!method initialize
    # @!attribute [r] datasource
    param :datasource

    def rebuild =->(datasource) { self.class.new(datasource) }
  end
end
