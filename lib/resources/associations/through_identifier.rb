# frozen_string_literal: true

module Resources
  module Associations
    class ThroughIdentifier
      attr_reader :source, :through_assoc_name, :target_assoc_name

      # source, through, target, assoc_name
      # has_many :parents, through: :children, assoc_name: :parents
      #
      # @param through <Symbol> name of join relation
      # @param name <Symbol> association name
      # @assoc_name <Symbol> explicit assoc_name provision
      def self.[](source, assoc_name, through_assoc_name, through_assoc_target_name = nil, &block)
        return unless through_assoc_name.present?

        new(source, through_assoc_name, through_assoc_target_name || assoc_name).then(&block)
      end

      def initialize(*args)
        @source, @through_assoc_name, @target_assoc_name = *args
      end

      def join_relation
        source.associations[through_assoc_name] || raise(ArgumentError, "Association #{through_assoc_name} not found on #{source}")
      end

      def target_relation
        join_relation.associations[target_assoc_name] || raise(ArgumentError, "Association #{target_assoc_name} not found on #{through_assoc_name}")
      end

      # @api private
      def to_sym
        source.name.to_s.to_sym
      end
    end
  end
end
