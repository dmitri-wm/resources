# frozen_string_literal: true

module Resources
  module AutoCurry
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def auto_curry(*names)
        names.each do |name|
          alias_method "original_#{name}", name

          define_method(name) do |*args, **kwargs, &block|
            method("original_#{name}").curry[*args, **kwargs, &block]
          end
        end
      end
    end
  end
end
