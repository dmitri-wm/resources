# frozen_string_literal: true

module Resources
  class AutoStruct
    IVAR = ->(v) { :"@#{v}" }

    def initialize(attributes)
      attributes.each do |key, value|
        instance_variable_set(IVAR[key], value)
      end
    end

    def respond_to_missing?(meth, include_private = false)
      super || instance_variables.include?(IVAR[meth])
    end

    def [](key)
      send(key)
    end

    private

    def method_missing(meth, *args, &block)
      ivar = IVAR[meth]

      if instance_variables.include?(ivar)
        instance_variable_get(ivar)
      else
        super
      end
    end
  end
end
