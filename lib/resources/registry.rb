# frozen_string_literal: true

require 'dry/core/class_builder'

module Resources
  module Registry
    def self.included(base)
      base.extend(ClassMethods)
    end

    module Namespaces
      def self.call(registry_name)
        unless const_defined?(registry_name.capitalize)
          Dry::Core::ClassBuilder.new(
            name: registry_name.capitalize,
            namespace: self,
            parent: Base
          ).call
        end

        const_get(registry_name.capitalize)
      end
    end

    module ClassMethods
      def register(into:, by:, default: -> { name.split('::').last.underscore.pluralize.to_sym }) # rubocop:disable Metrics/MethodLength
        registry_class = Resources::Registry::Namespaces.call(into)
        registry_name = into
        key_resolve_override = [into.to_s.singularize, by].join('_')

        singleton_class.class_eval do
          define_method registry_name do
            registry_class
          end
          alias_method into, registry_name

          define_method(:[]) do |key|
            public_send(registry_name)[key]
          end

          define_method key_resolve_override do |val = nil|
            return instance_variable_get(:@registry_key) if val.nil?

            resolved_key = val.respond_to?(:call) && instance_exec(&val) || val
            set_registry_key(resolved_key)
          end

          define_method :set_registry_key do |key|
            instance_variable_set(:@registry_key, key)
            public_send(registry_name)[key] = self
          end

          define_method :inherited do |subclass|
            super(subclass)

            resolved_key = subclass.instance_exec(&default)
            subclass.public_send(:set_registry_key, resolved_key)
          end
        end
      end
    end

    class Base
      class << self
        def store
          @store ||= Concurrent::Map.new
        end

        def []=(key, value)
          raise KeyError, "#{key} is already registered" if store.key?(key)

          store[key] = value
        end

        def [](key)
          store[key] || try_to_load(key) || raise(KeyError, "#{key} is not registered")
        end

        def key?(key)
          store.key?(key)
        end

        def try_to_load(_key); end
      end
    end
  end
end
