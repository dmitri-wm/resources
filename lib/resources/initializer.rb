module Resources
  module Initializer
    module DefineWithHook
      def param(...)
        super.tap { __define_with__ }
      end

      def option(...)
        super.tap do
          __define_with__ unless method_defined?(:with)
        end
      end

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

    def self.extended(base)
      base.extend(Dry::Initializer[undefined: false])
      base.extend(DefineWithHook)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def options
        @__options__ ||= self.class.dry_initializer.definitions.values.each_with_object({}) do |item, obj|
          obj[item.target] = instance_variable_get(item.ivar)
        end
      end

      define_method(:class, Kernel.instance_method(:class))
      define_method(:instance_variable_get, Kernel.instance_method(:instance_variable_get))

      def freeze
        options
        super
      end
    end
  end
end
