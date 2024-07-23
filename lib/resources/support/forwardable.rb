# frozen_string_literal: true

module Resources
  module Forwardable
    def forward(*methods, to:)
      methods.each do |method|
        define_method(method) do |*args, **kwargs, &block|
          send(to).send(method, *args, **kwargs, &block).then do |result|
            if respond_to?(:options)
              self.class.new(**options, to => result)
            else
              self.class.new(result)
            end
          end
        end
      end
    end

    # @param methods [Array<Symbol>]
    # @example
    #   load_on :find, from: :dataset
    #   load_on :find, :find_by, from: :dataset
    # Relation.find(1)
    # Will firstly fetch it from dataset and then pass to
    #  relation transfomator / mapper
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
