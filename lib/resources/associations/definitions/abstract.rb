# frozen_string_literal: true

# domain: Change Events

module Resources
  module Associations
    module Definitions
      class Abstract
        extend Dry::Initializer
        extend Dry::Core::ClassAttributes

        defines :result

        option :source # relation class that defines the association
        option :relation_name, Types::Symbol, optional: true # name of the relation
        option :name, Types::Symbol # name of the association
        option :result, Types::Strict::Symbol.enum(:one, :many), default: -> { self.class.result } # result type
        option :foreign_key, Types::Symbol, optional: true
        option :primary_key, Types::Symbol, default: -> { :id }
        option :through, optional: true
        option :view, Types::Symbol, optional: true
        option :combine_keys, optional: true
        option :condition, Types::Interface(:call), optional: true
        option :polymorphic, default: -> { false }
        option :as, Types::Symbol, optional: true

        def self.new(**opts)
          options = process_options(Hash[opts])

          super(**options)
        end

        def self.process_options(options)
          options[:relation_name] = options.delete(:relation) if options.key?(:relation)

          ThroughIdentifier[*options.values_at(:source, :name, :through, :assoc_name)] do |settings|
            options[:through] = settings
          end

          PolymorphicIdentifier[*options.values_at(:source, :polymorphic, :as, :name)] do |settings|
            options[:polymorphic] = settings
          end

          options
        end

        def target
          TargetIdentifier[name, relation_name]
        end

        def build_association(source:)
          "::Resources::#{source.class.adapter.to_s.classify}::Associations::#{self.class.name.demodulize}"
            .constantize.new(self, source:, target: target.new(context: source.context))
        end

        def call_association(source:)
          build_association(source:).call
        end

        def join_association(source:)
          build_association(source:).join
        end

        # memoize :target
      end
    end
  end
end
