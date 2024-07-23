# frozen_string_literal: true

module Resources
  module Associations
    # Abstract many-to-many association type
    #
    # @api public
    class HasManyThrough < Abstract
      attr_reader :join_relation

      # @api private
      def initialize(...)
        super
        @join_relation = through.join_association
      end

      # @api public
      def call(*)
        raise NotImplementedError
      end

      def foreign_key
        definition.foreign_key || join_relation.foreign_key(source.name)
      end

      def through
        definition.through
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

      protected

      def source_key
        source.primary_key
      end

      def target_key
        foreign_key
      end

      def join_assoc
        if join_relation.associations.key?(through.assoc_name)
          join_relation.associations[through.assoc_name]
        else
          join_relation.associations[through.target]
        end
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
