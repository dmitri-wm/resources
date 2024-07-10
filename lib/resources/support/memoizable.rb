module Resources
  module Memoizable
    MEMOIZED_HASH = {}.freeze

    module ClassInterface
      def memoize(*names)
        prepend(Memoizer.new(self, names))
      end

      def new(*)
        obj = super
        obj.instance_variable_set(:'@__memoized__', MEMOIZED_HASH.dup)
        obj
      end
      ruby2_keywords(:new) if respond_to?(:ruby2_keywords, true)
    end

    def self.included(klass)
      super
      klass.extend(ClassInterface)
    end

    attr_reader :__memoized__

    class Memoizer < Module
      attr_reader :klass, :names

      def initialize(klass, names)
        @names = names
        @klass = klass
        define_memoizable_names!
      end

      private

      def define_memoizable_names!
        names.each do |name|
          meth = klass.instance_method(name)

          if !meth.parameters.empty?
            define_method(name) do |*args|
              __memoized__[:"#{name}_#{args.hash}"] ||= super(*args)
            end
          else
            define_method(name) do
              __memoized__[name] ||= super()
            end
          end
        end
      end
    end
  end
end
