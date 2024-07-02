# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Relations
          module Adapters
            module Lib
              module Associations
                extend ActiveSupport::Concern

                included do
                  mstore :association_configs, key: :name, unique: true
                  store :associations, key: :name
                  store :associations_to_merge, storage: :array
                  attr_accessor :collection
                end

                class_methods do
                  def belongs_to(name, **options)
                    define_association(:belongs_to, name, options)
                  end

                  def has_many(name, **options)
                    define_association(:has_many, name, options)
                  end

                  def has_one(name, **options)
                    define_association(:has_one, name, options)
                  end

                  private

                  def define_association(type, name, options)
                    Entities::AssociationConfig.new(name: name, type: type, **options).tap(&store_association_config).then(&method(:define_association_method))
                  end

                  def define_association_method(association)
                    define_method(association.name) do
                      fetch_association(association.name)
                    end

                    alias_method association.name.to_s.pluralize, association.name
                  end

                  def store_association_config =->(c) { c.tap { association_configs << c } }
                end

                def store_collection
                  ->(data) { self.collection = data }
                end

                def to_config
                  ->(name) { self.class.association_configs.fetch(name) }
                end

                def fetch_association(name)
                  associations.fetch(name) or initialize_association(name)
                end

                def initialize_association(name)
                  name.then(&(to_config >> to_association >> store_association))
                end

                def store_association
                  ->(a) { a.tap { associations << a } }
                end

                def to_association
                  ->(config) { Entities::AssociationEntity.new(config: config, parent: self) }
                end

                def fetch_associations
                  self.associations ||= {}
                end

                def parse_associations(associations)
                  associations.each_with_object({}) do |association, hash|
                    case association
                    when Symbol, String
                      hash[association.to_sym] = {}
                    when Hash
                      association.each do |key, value|
                        hash[key.to_sym] = parse_associations(Array(value))
                      end
                    else
                      raise "Invalid association name #{association}"
                    end
                  end
                end

                def preload_associations(associations_schema, top_level: false)
                  Maybe(top_level.presence).fmap { associations_schema.keys }.value_or(associations_schema).each(&method(:preload_association))
                end

                def preload_association(name, nested_associations={})
                  send(name).preload_associations(nested_associations)
                end

                def with(*associations)
                  tap do
                    parse_associations(associations).
                      tap(&:prop_down_with).
                      then(&:keys).
                      tap(&method(:preload_associations)).
                      then(&method(:associations_to_merge=))
                  end
                end

                def prop_down_with(associations_schema)
                  associations_schema.each do |name, nested_associations|
                    send(name).with(nested_associations)
                  end
                end

                def fetch_collection(association_name)
                  fetch_collection_from_store(association_name).value_or(resolve_collection(association_name))
                end

                def fetch_collection_from_store(association_name)
                  Maybe(fetch_collection_store[association_name])
                end

                def resolve_collection(association_name)
                  fetch_association(association_name).then(&:method)
                end

                def fetch_collection_store
                  Maybe(collections).value_or(init_collections)
                end

                def init_collections
                  self.collections = {}
                end

                def merge_associations(record, associations)
                  associations_to_merge.map(&fetch_and_load).each(&:index)

                  associations.each_value do |association, nested_associations|
                    associated_data = record.send(association)
                    if nested_associations.any?
                      associated_data = if associated_data.is_a?(Array)
                        associated_data.map { |r| merge_associations(r, nested_associations) }
                      else
                        merge_associations(associated_data, nested_associations)
                      end
                    end
                    record.instance_variable_set("@#{association}", associated_data)
                    record.define_singleton_method(association) { instance_variable_get("@#{association}") }
                  end
                  record
                end

                def fetch_and_load
                  ->(name) { send(name).load }
                end
              end
            end
          end
        end
      end
    end
  end
end
