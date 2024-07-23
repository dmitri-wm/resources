# frozen_string_literal: true

module Resources
  # AutoStruct class provides a simple struct-like functionality
  class AutoStruct
    IVAR = ->(v) { :"@#{v}" }

    # Initialize a new AutoStruct instance
    #
    # @param attributes [Hash] A hash of attributes to set on the instance
    def initialize(attributes)
      attributes.each do |key, value|
        instance_variable_set(IVAR[key], value)
      end
    end

    # Check if the instance responds to a method
    #
    # @param meth [Symbol] The method name to check
    # @param include_private [Boolean] Whether to include private methods
    # @return [Boolean] True if the instance responds to the method, false otherwise
    def respond_to_missing?(meth, include_private = false)
      super || instance_variables.include?(IVAR[meth])
    end

    # Access an attribute using hash-like syntax
    #
    # @param key [Symbol] The attribute name to access
    # @return [Object] The value of the attribute
    def [](key)
      send(key)
    end

    private

    # Handle method calls for undefined methods
    #
    # @param meth [Symbol] The method name
    # @param args [Array] The arguments passed to the method
    # @param block [Proc] The block passed to the method
    # @return [Object] The value of the instance variable if it exists
    # @raise [NoMethodError] If the instance variable doesn't exist
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
