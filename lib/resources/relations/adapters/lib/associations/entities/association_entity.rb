# frozen_string_literal: true

# domain: Change Events

module Resources
  module Relations
    module Adapters
      module Lib
        module Associations
          module Entities
            class AssociationEntity
              KeyMap = Struct.new(:name, :data)

              extend Dry::Initializer
              include Dry::Monads[:maybe]
              include Memoizer
              include Storage

              store :key_mappings, attribute: :name

              attr_accessor :to_preload

              option :config,
                     AssociationConfig::ThroughRelation::Interface | AssociationConfig::DirectRelation::Interface
              option :parent, Types::Instance(Adapters::Base)

              delegate :where, :filter, :select, :paginate, :sort, :all, :pluck, :first, to: :child_relation
              delegate :name, to: :config

              memoize def child_relation
                config.relation.new(context: parent.context)
              end

              memoize def parent_relation
                parent.then(&apply_conditions)
              end

              def preload?
                !!to_preload
              end

              def preload
                self.to_preload = true
              end

              def all
                fetch_child_collection
              end
              alias to_a all

              def fetch_association
                config.respond_to?(:through) ? fetch_through_association : fetch_direct_association
              end

              def fetch_child_collection
                binding.pry
                fetch_association.all
              end

              def fetch_direct_association
                child_relation.where(child_key => parent_keys)
              end

              def store_key_map
                smart_group >> build_key_map >> add_to_store
              end

              def add_to_store
                ->(key_map) { key_mappings << key_map }
              end

              def build_key_map
                ->(data) { KeyMap.new(config.name, data) }
              end

              def smart_group
                ->(data) { data.each_with_object({}) { |e, obj| (obj[e.first] ||= Set.new).concat(e[1..]) } }
              end

              def parent_keys
                keys.map(&:last).uniq
              end

              def fetch_keys
                parent_relation.pluck(:id, parent_key)
              end

              memoize def keys
                fetch_keys
              end

              def build_relation
                ->(relation) { relation.new(context: context) }
              end

              def fetch_through_association
                [config.source, fetch_association(config.through)].then(&method(:fetch_source_association).curry)
              end

              def fetch_source_association(through_association, source)
                Maybe(through_association.send(source))
              end

              memoize def parent_key
                case config.type
                when :belongs_to
                  config.foreign_key
                when :has_many
                  config.primary_key
                when :has_one
                  config.primary_key
                else
                  raise "Unknown association type: #{association.type}"
                end
              end

              memoize def child_key
                case config.type
                when :belongs_to
                  config.primary_key
                when :has_many
                  config.foreign_key
                when :has_one
                  config.foreign_key
                else
                  raise "Unknown association type: #{association.type}"
                end
              end

              def apply_conditions
                ->(relation) { Maybe(config.conditions && relation).bind(&apply_query).value_or(relation) }
              end

              def apply_query
                ->(query) { query.call(self) }
              end
            end
          end
        end
      end
    end
  end
end
