# frozen_string_literal: true

# domain: Change Events

module Resources
  module Relations
    module Definitions
      class Abstract
        extend Dry::Initializer
        extend Dry::Core::ClassAttributes

        defines :result

        option :source, Types::Inherited.from(Relation)
        option :target, Types::Inherited.from(Relation)
        option :name, Types::Symbol
        option :result, Types::Strict::Symbol.enum(:one, :many), default: -> { self.class.result }
        option :type, Types::Symbol.enum(:belongs_to, :has_many, :has_one)
        option :foreign_key, Types::Symbol, optional: true
        option :primary_key, Types::Symbol.default(:id), optional: true
        option :through, Types::Symbol, optional: true
        option :source, Types::Symbol, optional: true
        option :view, Types::Symbol, optional: true
        option :combine_keys, optional: true

        def self.new(**opts)
          options = process_options(Hash[opts])

          super(**options)
        end

        # @api private
        def self.process_options(options)
          target = options[:target]
          through = options[:through]

          options[:through] = ThroughIdentifier[through, target, options[:assoc]] if through

          options[:name] = target

          options
        end
      end
    end
  end
end
