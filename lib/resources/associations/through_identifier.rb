# frozen_string_literal: true

module Resources
  module Associations
    class ThroughIdentifier
      attr_reader :through, :target, :assoc_name

      def self.[](source, target, assoc_name = nil)
        new(source, target, assoc_name || default_assoc_name(target))
      end

      def self.default_assoc_name(relation)
        Inflector.singularize(relation).to_sym
      end

      def initialize(through, target, assoc_name)
        @through = through
        @target = target
        @assoc_name = assoc_name
      end

      def relation
        through.associations[assoc_name] || through.associations[target]
      end

      # @api private
      def to_sym
        source.name
      end
    end
  end
end
