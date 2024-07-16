# frozen_string_literal: true

# domain: Change Events

module Resources
  module Relation
    module Forwardable
      extend Concern

      included do
        # extend original ruby module
        extend ::Forwardable
      end

      class_methods do
        def forward(*methods, to:)
          methods.each do |method|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method}(*args, &block)
                new(#{to}.__send__(:#{method}, *args, &block))
              end
            RUBY
          end
        end
      end
    end
  end
end
