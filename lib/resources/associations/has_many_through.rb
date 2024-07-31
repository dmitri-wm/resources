# frozen_string_literal: true

module Resources
  module Associations
    # Abstract many-to-many association type
    #
    # @api public
    class HasManyThrough < Abstract
      attr_reader :join_relation, :through_identifier

      # @api private
      def initialize(...)
        super
        @join_relation = through.join_relation
        @through_identifier = through.call(source)
      end

      # @api public
      def call(*)
        raise NotImplementedError
      end

      def foreign_key
        definition.foreign_key || join_relation.foreign_key(source.name)
      end

      def associate(children, parent)
        ((spk, sfk), (tfk, tpk)) = join_key_map
        case parent
        when Array
          parent.map { |p| associate(children, p) }.flatten(1)
        else
          children.map do |tuple|
            { sfk => tuple.fetch(spk), tfk => parent.fetch(tpk) }
          end
        end
      end

      def source_key
        source.primary_key
      end

      def target_key
        foreign_key
      end

      def through_association
        through_identifier.join_association
      end

      def through_assoc_name
        through_identifier.through_assoc_name
      end

      def target_assoc_name
        through_identifier.target_assoc_name
      end

      def target_association
        through_identifier.target_association
      end

      def target_relation
        through_identifier.target_relation
      end

      def through_relation
        through_identifier.join_relation
      end

      def join_assoc
        through_identifier.target_association
      end

      # @description
      #   Returns the join key map for the association.
      #   The join key map is an array of arrays, where each inner array
      #   represents the join key for the associations
      # @example
      #   class Parent
      #     has_many :children
      #     has_many :grand_children, through: :children
      #   end
      #   class Child
      #     belongs_to :parent
      #     has_many :grand_children
      #   end
      #   class GrandChild
      #     belongs_to :child
      #   end
      #   Parent.associations[:children].join_key_map => [[:parent_id, :child_id]]
      #   Child.associations[:grand_children].join_key_map => [[:child_id, :grand_child_id]]
      #   Parent.associations[:grand_children].join_key_map => [[:parent_id, :child_id], [:child_id, :grand_child_id]]
      def join_key_map
        left = super
        right = join_assoc.join_key_map

        [left, right]
      end

      memoize :foreign_key, :join_assoc, :join_key_map
    end
  end
end
