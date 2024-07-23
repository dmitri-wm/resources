# frozen_string_literal: true

module Resources
  # The Initializer module provides enhanced initialization capabilities
  # for classes, including automatic generation of a `with` method for
  # creating new instances with modified attributes.
  module Initializer
    # DefineWithHook module adds functionality to automatically define
    # a `with` method when params or options are added to a class.
    module DefineWithHook
      # Extends the functionality of Dry::Initializer's `param` method
      # to automatically define the `with` method.
      #
      # @param args Arguments passed to Dry::Initializer's `param` method
      def param(*args)
        super.tap { __define_with__ }
      end

      # Extends the functionality of Dry::Initializer's `option` method
      # to automatically define the `with` method if it doesn't exist.
      #
      # @param args Arguments passed to Dry::Initializer's `option` method
      def option(*args)
        super.tap do
          __define_with__ unless method_defined?(:with)
        end
      end

      private

      # Defines the `with` method for creating new instances with modified attributes.
      def __define_with__
        seq_names = dry_initializer
                    .definitions
                    .reject { |_, d| d.option }
                    .keys
                    .join(', ')

        seq_names << ', ' unless seq_names.empty?

        undef_method(:with) if method_defined?(:with)

        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def with(**new_options)
            if new_options.empty?
              self
            else
              self.class.new(#{seq_names}**options, **new_options)
            end
          end
        RUBY
      end
    end

    # Extends the base class with Dry::Initializer, DefineWithHook,
    # and includes InstanceMethods.
    #
    # @param base [Class] The class being extended
    def self.extended(base)
      base.extend(Dry::Initializer[undefined: false])
      base.extend(DefineWithHook)
      base.include(InstanceMethods)
    end

    # InstanceMethods module provides additional functionality
    # for instances of classes using the Initializer module.
    module InstanceMethods
      # Returns a hash of all initialized options.
      #
      # @return [Hash] A hash containing all initialized options
      def options
        @__options__ ||= self.class.dry_initializer.definitions.values.each_with_object({}) do |item, obj|
          obj[item.target] = instance_variable_get(item.ivar)
        end
      end

      # Ensure proper behavior of `class` method
      define_method(:class, Kernel.instance_method(:class))

      # Ensure proper behavior of `instance_variable_get` method
      define_method(:instance_variable_get, Kernel.instance_method(:instance_variable_get))

      # Extends the `freeze` method to ensure options are calculated before freezing.
      #
      # @return [Object] The frozen object
      def freeze
        options
        super
      end
    end
  end
end
