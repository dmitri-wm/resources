# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Relations
          module Adapters
            module Lib
              module Storage
                def self.included(base)
                  base.extend(HasStore)
                end

                class Store
                  def self.build(storage: :hash, **)
                    case Types::Coercible::Symbol.enum(:hash, :array)[storage]
                    in :hash then HashStore.new(**)
                    in :array then ArrayStore.new(**)
                    else raise Dry::Types::ConstraintError, "Invalid store type: #{storage}"
                    end
                  end

                  module Exceptions
                    class UniqueError < Dry::Types::ConstraintError; end

                    def fail_unique(key)
                      raise(UniqueError.new("#{key} already present in storage", store))
                    end
                  end

                  class Base
                    # @abstract

                    include Exceptions
                    include Memoizer
                    extend Dry::Initializer

                    delegate :[], :delete, :clear, to: :store

                    option :unique, Types::Bool.default(false), optional: true, comment: 'If true, store will not allow duplicates and will raise exception if duplicate is added'

                    memoize def store = raise(NotImplementedError)

                    def <<(o) = raise(NotImplementedError)
                    alias_method :add, :<<

                    def include?(o) = raise(NotImplementedError)
                  end

                  class HashStore < Base
                    KeyPair = Struct.new(:key, :val)

                    option :key, Types::Coercible::Symbol | Types::Interface(:call), optional: true, comment: 'Attribute to use as key for hash store can be symbol or proc'

                    delegate :key?, to: :store

                    alias_method :fetch, :[]

                    memoize def store = {}

                    def <<(object) = object.then(&(to_key_pair >> uniq_check >> add_to_store))

                    def to_key_pair =->(o) { KeyPair.new(fetch_key(o), o) }

                    def fetch_key(o) = key.is_a?(Symbol) ? o.public_send(key) : key.call(o)

                    def uniq_check =->(kp) { unique && key?(kp.key) ? fail_unique(kp.key) : kp }

                    def add_to_store =->(kp) { store.merge!(kp.key => kp.val) }

                    def include?(object) = object.is_a?(Symbol) ? key?(object) : key?(fetch_key(object))
                  end

                  class ArrayStore < Base
                    delegate :include?, to: :store

                    memoize def store = unique ? Set.new : []

                    def <<(object)= object.then(&(unique_check >> add_to_store))

                    def unique_check =->(it) { unique && include?(it) ? fail_unique(it) : it }

                    def add_to_store =->(it) { store << it }
                  end
                end

                module HasStore
                  # @description defines store method for instance
                  #
                  # @param name [Symbol] name of the store
                  # @options [Hash] options
                  #  @option :type [Symbol] type of store, :hash or :array
                  #  @option :attribute [Symbol] attribute to use as key for hash store, ignored for array store
                  #  @option :unique [Boolean] if true, store will not allow duplicates and will raise exception if duplicate is added
                  # @example with :key as symbol
                  #   class Storable
                  #     store :collection, key: :id, type: :hash
                  #   end
                  #
                  #   storable = Storable.new
                  #   storable.collection << OpenStruct.new(id: 1, name: 'foo')
                  #   storable.collection.add(OpenStruct.new(id: 2, name: 'bar'))
                  #
                  #   puts storable.collection
                  #   => { 1 => #<OpenStruct id=1, name="foo">, 2 => #<OpenStruct id=2, name="bar"> }
                  # @example with :key as proc
                  #   class Storable
                  #     store :collection, key: ->(o) { #{o.id}-#{o.name} }, type: :hash
                  #   end
                  #
                  #   storable = Storable.new
                  #   storable.collection << OpenStruct.new(id: 1, name: 'foo')
                  #   storable.collection.add(OpenStruct.new(id: 1, name: 'bar'))
                  #   puts storable.collection
                  #   => { "1-foo" => #<OpenStruct id=1, name="foo">, "2-bar" => #<OpenStruct id=2, name="bar"> }
                  # @example with :unique true
                  #  class Storable
                  #   store :collection, key: :id, type: :hash, unique: true
                  # end
                  # storable = Storable.new
                  # storable.collection << OpenStruct.new(id: 1, name: 'foo')
                  # storable.collection.add(OpenStruct.new(id: 1, name: 'bar'))
                  # => raises Dry::Types::ConstraintError
                  def store(name, **)
                    define_method name do
                      instance_variable_get(:"@#{name}") || instance_variable_set(:"@#{name}", Store.build(**))
                    end
                  end

                  # @description defines store method for class
                  # @param (@see #store)
                  # @options (@see #store)
                  def mstore(name, **)
                    define_singleton_method name do
                      instance_variable_get(:"@#{name}") || instance_variable_set(:"@#{name}", Store.build(**))
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
