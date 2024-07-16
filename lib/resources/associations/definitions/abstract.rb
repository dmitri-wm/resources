# frozen_string_literal: true

# domain: Change Events

module Resources
  module Relations
    module Definitions
      class Abstract
        extend Dry::Initializer
        extend Dry::Core::ClassAttributes

        defines :result

        option :source, Types::Inherited.from(Relation) # relation class that defines the association
        option :target, Types::Inherited.from(Relation) # relation class that is associated with
        option :name, Types::Symbol # name of the association
        option :result, Types::Strict::Symbol.enum(:one, :many), default: -> { self.class.result } # result type
        option :type, Types::Symbol.enum(:belongs_to, :has_many, :has_one) # type of the association
        option :foreign_key, Types::Symbol, optional: true
        option :primary_key, Types::Symbol.default(:id), optional: true
        option :through, Types::Symbol, optional: true
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
