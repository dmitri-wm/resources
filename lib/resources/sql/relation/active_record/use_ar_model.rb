# frozen_string_literal: true

# domain: Change Events

require 'dry/core/class_builder'

module Resources
  module Sql
    module Relation
      # ActiveRecord class provides an ActiveRecord-based implementation of the SQL Relation
      class ActiveRecord
        class RelationName
          include Dry::Equalizer(:relation_name)

          attr_reader :relation_name

          def initialize(association)
            @relation_name = Inflector.pluralize(association.relation_name.presence || association.name).to_sym
          end

          def constantize
            ::Resources::Relation[relation_name].ar_model_class
          end

          def to_s
            self
          end

          def -@
            self
          end

          def start_with?(string)
            string == '::'
          end
        end

        module UseArModel
          extend Concern

          included do
            include UseContextScope

            defines :ar_model_class

            delegate :ar_model_class, to: :class
          end

          class_methods do
            # Sets the ActiveRecord model to be used by this relation
            #
            # @param table_name [String, Symbol] The ActiveRecord model class, table name, or symbol
            # @return [void]
            #
            # @example Set User model as the AR model
            #   use_ar_model User
            def use_ar_model(klass)
              ar_model_class build_ar_model_class(klass)
              define_context_conditions(ar_model_class)
            end

            def build_ar_model_class(klass)
              child_klass = Class.new(klass)
              model_name = klass.table_name.classify.to_sym
              const_set(model_name, child_klass)
              const_get(model_name)
            end

            def associate
              super
              define_ar_associations
            end

            def define_ar_associations
              associations.each_value do |association|
                assoc_type = Inflector.demodulize(association.class.name).underscore

                if assoc_type.include?('_through')
                  ar_model_class.send(assoc_type.gsub('_through', ''), association.name, **through_definition_options(association.through))
                else
                  ar_model_class.send(assoc_type, association.name, **definition_options(association))
                end
              end
            end

            def target_class_name(association)
              RelationName.new(association).freeze
            end

            def definition_options(association)
              {
                class_name: target_class_name(association),
                foreign_key: association.foreign_key
              }
            end

            def through_definition_options(through)
              {
                through: through.through_assoc_name,
                source: through.target_assoc_name
              }
            end
          end
        end
      end
    end
  end
end
