# frozen_string_literal: true

module Resources
  module Pipeline
    module Operator
      def >>(other)
        composite_class.new(self, other)
      end

      private

      def composite_class
        raise NotImplementedError
      end
    end

    include Operator

    # @api public
    def map_with(*names)
      [self, *names.map { |name| mappers[name] }]
        .reduce { |a, e| composite_class.new(a, e) }
    end

    module Proxy
      def respond_to_missing?(name, include_private = false)
        left.respond_to?(name) || super
      end

      private

      def decorate?(response)
        response.is_a?(left.class)
      end

      def method_missing(name, *args, &block)
        if left.respond_to?(name)
          response = left.__send__(name, *args, &block)

          if decorate?(response)
            self.class.new(response, right)
          else
            response
          end
        else
          super
        end
      end
    end

    class Composite
      (Kernel.private_instance_methods - %i[respond_to_missing? block_given?])
        .each(&method(:undef_method))

      include Dry::Equalizer(:left, :right)
      include Proxy

      attr_reader :left
      attr_reader :right

      def initialize(left, right)
        @left = left
        @right = right
      end

      def >>(other)
        self.class.new(self, other)
      end
    end
  end
end
