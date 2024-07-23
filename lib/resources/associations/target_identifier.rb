# frozen_string_literal: true

module Resources
  module Associations
    module TargetIdentifier
      include AutoCurry
      extend self

      # Resolves the target relation and yields the result
      # @param name [Symbol] The name of the association
      # @param relation [Class, Symbol, String, nil] The relation to resolve
      # @yield [Class] The resolved relation class
      def call(name, relation)
        resolve_target(name, relation)
      end
      alias [] call

      private

      # Resolves the target relation based on the input
      # @param name [Symbol] The name of the association
      # @param relation [Class, Symbol, String, nil] The relation to resolve
      # @return [Class] The resolved relation class
      # @raise [ArgumentError] If the relation cannot be resolved
      def resolve_target(name, relation)
        case relation
        when nil             then infer_target_from_name(name)
        when relation_class? then relation
        when Symbol, String  then resolve_relation(relation)
        else raise ArgumentError, "Unknown target: #{relation}"
        end
      end

      # Infers the target relation from the association name
      # @param name [Symbol] The name of the association
      # @return [Class] The inferred relation class
      def infer_target_from_name(name)
        resolve_relation(name.to_s.pluralize.to_sym)
      end

      # Resolves the relation based on registry lookup or constant resolution
      # @param relation [Symbol, String] The relation to resolve
      # @return [Class] The resolved relation class
      # @raise [NameError] If the relation cannot be resolved
      def resolve_relation(relation)
        case relation
        when in_registry? then Resources::Relation[relation.to_sym]
        when camel_case?  then relation.to_s.constantize
        else raise NameError, "Couldn't resolve relation #{relation}"
        end
      end

      # Checks if the target is a subclass of Resources::Relation
      # @param target [Object] The object to check
      # @return [Boolean] True if the target is a subclass of Resources::Relation
      def relation_class?(target)
        target.is_a?(Class) && target < Resources::Relation
      end

      # Checks if the relation is in the registry
      # @param relation [Symbol, String] The relation to check
      # @return [Boolean] True if the relation is in the registry
      def in_registry?(relation)
        Resources::Relation.relations.key?(relation.to_sym)
      end

      # Checks if the relation name is in CamelCase
      # @param relation [Symbol, String] The relation to check
      # @return [Boolean] True if the relation name is in CamelCase
      def camel_case?(relation)
        (relation.to_s =~ /^[A-Z]/).present?
      end

      auto_curry :relation_class?, :in_registry?, :camel_case?
    end
  end
end
