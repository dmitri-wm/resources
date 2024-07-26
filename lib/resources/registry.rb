# frozen_string_literal: true

require 'dry/core/class_builder'

module Resources
  # The Registry module provides a flexible way to register and retrieve classes
  # It allows for automatic registration of subclasses and custom key resolution
  #
  # Example usage:
  #   class Parent
  #     include Resources::Registry
  #     register into: :childgarden, by: :name
  #   end
  #
  #   class Happy < Parent
  #   end
  #
  #   class Ugly < Parent
  #     childgarden_name :handsome
  #   end
  #
  #   Parent[:happy] # => Happy
  #   Parent[:handsome] # => Ugly
  #   Resources::Registry::Namespaces::Childgarden[:happy] # => Happy
  module Registry
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Namespaces module dynamically creates registry classes
    module Namespaces
      # Creates or retrieves a registry class for a given name
      # @param registry_name [String, Symbol] The name of the registry
      # @return [Class] The registry class
      #
      # Example:
      #   Resources::Registry::Namespaces.call(:childgarden)
      #   # => Creates Resources::Registry::Namespaces::Childgarden class
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

    # ClassMethods module provides class-level methods for registration
    module ClassMethods
      # Registers the class in a specified registry
      # @param into [Symbol] The name of the registry to register into
      # @param by [Symbol] The method to use for key generation
      # @param default [Proc] A proc to generate a default key (optional)
      #
      # Example:
      #   class Parent
      #     include Resources::Registry
      #     register into: :childgarden, by: :name
      #   end
      def register(into:, by:, default: -> { name.split('::').last.underscore.pluralize.to_sym })
        registry_class = Resources::Registry::Namespaces.call(into)
        registry_name = into
        key_resolve_override = [into.to_s.singularize, by].join('_')

        define_registry_methods(registry_class, registry_name, key_resolve_override, default)
      end

      private

      # Defines methods for interacting with the registry
      def define_registry_methods(registry_class, registry_name, key_resolve_override, default)
        singleton_class.class_eval do
          # Defines a method to access the registry
          define_method registry_name do
            registry_class
          end
          alias_method :into, registry_name

          # Defines a method to retrieve items from the registry
          # Example: Parent[:happy] # => Happy
          define_method(:[]) do |key|
            public_send(registry_name)[key]
          end

          # Defines a method to set or get the registry key
          # Example: Ugly.childgarden_name(:handsome)
          define_method key_resolve_override do |val = nil|
            return registry_key if registry_key.present? || val.nil?

            resolved_key = val.respond_to?(:call) ? instance_exec(&val) : val
            set_registry_key(resolved_key)
          end

          define_method :registry_key do
            instance_variable_get(:@registry_key)
          end

          # Defines a method to set the registry key
          define_method :set_registry_key do |key|
            instance_variable_set(:@registry_key, key)
            public_send(registry_name)[key] = self
          end

          # Overrides the inherited method to automatically register subclasses
          # This allows Happy to be automatically registered as :happy
          define_method :inherited do |subclass|
            super(subclass)

            puts "inherited #{subclass}"
            # Schedule the callback to be executed after the class definition is complete
            TracePoint.new(:end) do |tp|
              if tp.self == subclass
                puts "Resolved: #{subclass}"
                puts "Key: #{subclass.registry_key}"

                next if subclass.registry_key.present?

                puts "sending default to #{subclass}"
                puts "sending default to #{subclass.instance_exec(&default)}"
                subclass.public_send(key_resolve_override, default)

                tp.disable
              end
            end.enable
          end
        end
      end
    end

    # Base class for all registries
    class Base
      class << self
        # Returns the store for the registry
        def store
          @store ||= Concurrent::Map.new
        end

        # Adds a new item to the registry
        # @raise [KeyError] if the key is already registered
        #
        # Example:
        #   Resources::Registry::Namespaces::Childgarden[:happy] = Happy
        def []=(key, value)
          raise KeyError, "#{key} is already registered" if store.key?(key)

          store[key] = value
        end

        # Retrieves an item from the registry
        # @raise [KeyError] if the key is not registered
        #
        # Example:
        #   Resources::Registry::Namespaces::Childgarden[:happy] # => Happy
        def [](key)
          store[key] || try_to_load(key) || raise(KeyError, "#{key} is not registered")
        end

        # Checks if a key exists in the registry
        #
        # Example:
        #   Resources::Registry::Namespaces::Childgarden.key?(:happy) # => true
        def key?(key)
          store.key?(key)
        end

        # Hook method for lazy loading (to be implemented by subclasses if needed)
        def try_to_load(_key); end
      end
    end
  end
end
