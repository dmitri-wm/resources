# frozen_string_literal: true

module Resources
  # The Memoizable module provides a way to easily memoize method results,
  # improving performance by caching the results of expensive computations.
  module Memoizable
    MEMOIZED_HASH = {}.freeze

    module ClassInterface
      # Memoizes the specified methods.
      #
      # @param names [Array<Symbol>] The names of the methods to memoize.
      def memoize(*names)
        prepend(Memoizer.new(self, names))
      end

      # Initializes a new instance with a memoization cache.
      def new(...)
        obj = super
        obj.instance_variable_set(:'@__memoized__', MEMOIZED_HASH.dup)
        obj
      end
    end

    def self.included(klass)
      super
      klass.extend(ClassInterface)
    end

    # The memoization cache for the instance.
    attr_reader :__memoized__

    # The Memoizer class is responsible for creating memoized versions of methods.
    class Memoizer < Module
      attr_reader :klass, :names

      # Initializes a new Memoizer.
      #
      # @param klass [Class] The class whose methods are being memoized.
      # @param names [Array<Symbol>] The names of the methods to memoize.
      def initialize(klass, names)
        @names = names
        @klass = klass
        define_memoizable_names!
      end

      private

      # Defines memoized versions of the specified methods.
      def define_memoizable_names!
        names.each do |name|
          meth = klass.instance_method(name)

          if !meth.parameters.empty?
            # For methods with parameters, use the hash of the arguments as part of the memoization key.
            define_method(name) do |*args|
              __memoized__[:"#{name}_#{args.hash}"] ||= super(*args)
            end
          else
            # For methods without parameters, use the method name as the memoization key.
            define_method(name) do
              __memoized__[name] ||= super()
            end
          end
        end
      end
    end
  end
end
