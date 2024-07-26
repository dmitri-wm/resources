# frozen_string_literal: true

module Resources
  # The Forwardable module provides methods to easily delegate method calls
  # to another object or to load data from a dataset.
  module Forwardable
    # Forwards method calls to another object and wraps the result in a new instance.
    #
    # @param methods [Array<Symbol>] The methods to be forwarded.
    # @param to [Symbol] The name of the method that returns the object to forward to.
    #
    # @example
    #   forward :count, :size, to: :array
    def forward(*methods, to:)
      methods.each do |method|
        define_method(method) do |*args, **kwargs, &block|
          acceptor = send(to)
          acceptor.send(method, *args, **kwargs, &block).then do |result|
            if respond_to?(:with)
              send(:with, to => result)
            else
              self.class.new(**options, to => result)
            end
          end
        end
      end
    end

    # Defines methods that load data from a dataset and wrap the result in a new instance.
    #
    # @param methods [Array<Symbol>] The methods to be defined for loading data.
    #
    # @example
    #   load_on :find, :find_by
    #   # This allows calling Relation.find(1), which will fetch from dataset
    #   # and pass to relation transformer/mapper
    def load_on(*methods)
      methods.each do |method|
        define_method(method) do |*args, **kwargs, &block|
          dataset.send(method, *args, **kwargs, &block).then do |result|
            self.class.new(**options, dataset: Array(result)).one
          end
        end
      end
    end
  end
end
