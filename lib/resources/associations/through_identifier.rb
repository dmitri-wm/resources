# frozen_string_literal: true

module Resources
  module Associations
    # Represents a through association between resources
    class ThroughIdentifier
      # @!attribute [r] source
      #   @return [Class] The source class for the association
      attr_reader :source

      # @!attribute [r] through_assoc_name
      #   @return [Symbol] The name of the through association
      attr_reader :through_assoc_name

      # @!attribute [r] target_assoc_name
      #   @return [Symbol] The name of the target association
      attr_reader :target_assoc_name

      # @param source [Class] The source class for the association
      # @param through_assoc_name [Symbol] The name of the through association
      # @param target_assoc_name [Symbol] The name of the target association
      # @param through_assoc_target_name [Symbol, nil] The name of the target association for the through association
      # @return [ThroughIdentifier] A new instance of ThroughIdentifier
      def self.[](source, assoc_name, through_assoc_name, through_assoc_target_name = nil, &block)
        return unless through_assoc_name.present?

        new(source, through_assoc_name, through_assoc_target_name || assoc_name).then(&block)
      end

      # @param source [Class] The source class for the association
      # @param through_assoc_name [Symbol] The name of the through association
      # @param target_assoc_name [Symbol] The name of the target association
      def initialize(source, through_assoc_name, target_assoc_name)
        @source = source
        @through_assoc_name = through_assoc_name
        @target_assoc_name = target_assoc_name
      end

      # @return [Object] The join relation for the through association
      def join_relation
        source.associations[through_assoc_name] || raise(ArgumentError, "Association #{through_assoc_name} not found on #{source}")
      end

      # @return [Object] The target relation for the association
      def target_relation
        join_relation.associations[target_assoc_name] || raise(ArgumentError, "Association #{target_assoc_name} not found on #{through_assoc_name}")
      end

      # @api private
      # @return [Symbol] The name of the source class as a symbol
      def to_sym
        source.name.to_s.to_sym
      end
    end
  end
end
