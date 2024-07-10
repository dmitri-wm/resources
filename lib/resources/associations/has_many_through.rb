module Resources
  module Associations
    # Abstract many-to-many association type
    #
    # @api public
    class HasManyThrough < Abstract
      attr_reader :join_relation

      # @api private
      def initialize(*)
        super
        @join_relation = through.relation
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

      def join_key_map
        left = super
        right = join_assoc.join_key_map

        [left, right]
      end

      memoize :foreign_key, :join_assoc, :join_key_map
    end
  end
end
