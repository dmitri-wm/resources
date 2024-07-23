# frozen_string_literal: true

# Domain: Change Events
# This module provides flexible storage mechanisms for resources

module Resources
  module Storage
    def self.included(base)
      base.extend(HasStore)
    end

    class Store
      # Factory method to create appropriate store based on the storage type
      def self.build(storage: :hash, **)
        case Types::Coercible::Symbol.enum(:hash, :array)[storage]
        in :hash then HashStore.new(**)
        in :array then ArrayStore.new(**)
        else raise Dry::Types::ConstraintError, "Invalid store type: #{storage}"
        end
      end

      module Exceptions
        class UniqueError < Dry::Types::ConstraintError; end

        # Raises a UniqueError when a duplicate key is attempted to be added
        def fail_unique(key)
          raise(UniqueError.new("#{key} already present in storage", store))
        end
      end

      # Base class for all store types
      class Base
        include Exceptions
        extend Dry::Initializer

        delegate :[], :delete, :clear, to: :store

        option :unique, Types::Bool.default(false), optional: true,
               comment: 'If true, store will not allow duplicates and will raise exception if duplicate is added'

        # Abstract methods to be implemented by subclasses
        def store = raise(NotImplementedError)
        def <<(o) = raise(NotImplementedError)
        def include?(o) = raise(NotImplementedError)
      end

      # Implementation of a hash-based store
      class HashStore < Base
        KeyPair = Struct.new(:key, :val)

        option :attribute, Types::Coercible::Symbol | Types::Interface(:call), optional: true,
               comment: 'Attribute to use as key for hash store can be symbol or proc'
        option :store, default: -> { {} }
        delegate :key?, :values, :each_value, :each, to: :store

        alias fetch []

        # Adds an object to the store
        def <<(object) = object.then(&(to_key_pair >> uniq_check >> add_to_store))
        alias add <<

        # Converts an object to a KeyPair
        def to_key_pair =->(o) { KeyPair.new(fetch_key(o), o) }

        # Fetches the key for an object based on the attribute
        def fetch_key(o) = attribute.is_a?(Symbol) ? o.public_send(attribute) : attribute.call(o)

        # Checks for uniqueness if the unique option is set
        def uniq_check =->(kp) { unique && key?(kp.key) ? fail_unique(kp.key) : kp }

        # Adds the KeyPair to the store
        def add_to_store =->(kp) { store[kp.key] = kp.val }

        # Checks if an object or key is present in the store
        def include?(object) = object.is_a?(Symbol) ? key?(object) : key?(fetch_key(object))
      end

      # Implementation of an array-based store
      class ArrayStore < Base
        option :store, default: -> { unique ? Set.new : [] }

        delegate :include?, :each, to: :store

        # Adds an object to the store
        def <<(object)= object.then(&(unique_check >> add_to_store))

        # Checks for uniqueness if the unique option is set
        def unique_check =->(it) { unique && include?(it) ? fail_unique(it) : it }

        # Adds the object to the store
        def add_to_store =->(it) { store << it }
      end
    end

    module HasStore
      # Defines a store method for an instance
      #
      # @param name [Symbol] name of the store
      # @param [Hash] options
      # @option options [Symbol] :type type of store, :hash or :array
      # @option options [Symbol, Proc] :attribute attribute to use as key for hash store, ignored for array store
      # @option options [Boolean] :unique if true, store will not allow duplicates and will raise exception if duplicate is added
      def store(name, **)
        define_method(name) do
          instance_variable_get(:"@#{name}") || instance_variable_set(:"@#{name}", Store.build(**))
        end
      end

      # Defines a store method for a class
      #
      # @param (see #store)
      # @option (see #store)
      def mstore(name, attribute: nil, unique: false, storage: :hash)
        define_singleton_method(name) do
          instance_variable_get(:"@#{name}") || instance_variable_set(:"@#{name}", Store.build(attribute: attribute, unique: unique, storage: storage))
        end
      end
    end
  end
end