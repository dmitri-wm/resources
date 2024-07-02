# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Relations
          module Adapters
            module Lib
              module UseEntityMapper
                extend ActiveSupport::Concern
                # This module provides a way to map data to entities using a custom mapper.
                # It allows setting a default entity mapper for the class and a custom mapper for a specific instance.
                # The mapper can be a class or a proc that accepts a single argument and returns the mapped data.
                #
                # @example Custom Entity Mapper Class
                #   class Mapper
                #     attr_reader :data
                #
                #     def initialize(data)
                #       @data = data
                #     end
                #
                #     def [](attr)
                #       data[attr]
                #     end
                #   end
                #
                #   class Collection
                #     include Lib::UseEntityMapper
                #
                #     default_entity_mapper Mapper
                #   end
                #
                # @example Proc as Entity Mapper
                #   class Collection
                #     include Lib::UseEntityMapper
                #     default_entity_mapper ->(data) { data.to_h }
                #   end
                attr_accessor :entity_mapper, :collection_entity_mapper

                class_methods do
                  # Sets the default entity mapper for the class.
                  #
                  # @param entity_mapper [Class, Proc] The entity mapper to use. It can be a class or a proc.
                  # @example
                  #   class Collection
                  #     include Lib::UseEntityMapper
                  #     default_entity_mapper Mapper
                  #   end
                  # @example
                  #   class Collection
                  #     include Lib::UseEntityMapper
                  #     default_entity_mapper ->(data) { data.to_h }
                  #   end
                  def default_entity_mapper(entity_mapper)
                    class_attribute :default_entity_mapper

                    self.default_entity_mapper = entity_mapper
                  end
                end

                # Sets a custom entity mapper for the instance.
                #
                # @param entity_mapper [Class, Proc] The entity mapper to use. It can be a class or a proc.
                # @return [self]
                def map_to(entity_mapper)
                  tap do |instance|
                    instance.entity_mapper = entity_mapper
                  end
                end

                # Sets a custom collection entity mapper for the instance.
                #
                # @param collection_entity_mapper [Class, Proc] The collection entity mapper to use. It can be a class or a proc.
                # @return [self]
                def map_collection_to(collection_entity_mapper)
                  tap do |instance|
                    instance.collection_entity_mapper = collection_entity_mapper
                  end
                end

                protected

                # Transforms data to an entity using a service call.
                # The service used for the transformation is determined by the `fetch_mapper` method.
                # @param data [Object] The data to be transformed.
                # @return [Object] The transformed entity.
                def to_entity =->(data) { service_call(service: fetch_mapper, data: data) }

                def fetch_mapper
                  entity_mapper || default_entity_mapper
                end

                def to_entities
                  ->(data) { collection_entity_mapper.presence ? build_collection_entities(data) : map_entities(data) }
                end

                def build_collection_entities(data)
                  if collection_entity_mapper.respond_to?(:call)
                    collection_entity_mapper.call(data)
                  elsif collection_entity_mapper.respond_to?(:new)
                    collection_entity_mapper.new(data)
                  else
                    raise "Invalid collection_entity_mapper: #{collection_entity_mapper}"
                  end
                end

                def map_entities(data)
                  data.map(&to_entity)
                end

                # Returns the default entity mapper for the class.
                #
                # @return [Class, Proc, nil] The default entity mapper or nil if not set.
                def default_entity_mapper
                  self.class.respond_to?(:default_entity_mapper) and self.class.default_entity_mapper
                end
              end
            end
          end
        end
      end
    end
  end
end
