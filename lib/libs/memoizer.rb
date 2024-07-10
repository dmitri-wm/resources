# frozen_string_literal: true

# domain: Core Frameworks

module Memoizer
  class UnsupportedMethod < StandardError; end

  def self.included(base)
    base.extend(self::ClassMethods)
  end

  def reset_memoizer_cache
    @__memo_cache = nil
    self
  end

  def preload_memoizer_cache(method_name, data)
    memoized_method_name = :"__memoized_#{method_name}"
    raise ArgumentError, <<~MESSAGE unless respond_to?(method_name, true) && respond_to?(memoized_method_name, true)
      #{method_name} is not a known memoized method
    MESSAGE

    @__memo_cache ||= {}
    @__memo_cache[method_name] = data

    self
  end

  module ClassMethods
    def memoize(*method_names)
      raise ArgumentError, "#memoize requires at least one method_name" if method_names.empty?

      method_names.each do |method_name|
        if instance_method(method_name).arity.nonzero?
          raise UnsupportedMethod, "#memoize currently only supports methods which take no arguments"
        end

        original_method = :"__non_memoized_#{method_name}"
        memoized_method = :"__memoized_#{method_name}"

        define_method memoized_method do
          @__memo_cache ||= {}
          @__memo_cache.fetch(method_name) do
            @__memo_cache[method_name] = send(original_method)
          end
        end

        alias_method original_method, method_name
        alias_method method_name, memoized_method
      end
    end
  end
end
