module Resources
  module Associations
    # Represents a polymorphic identifier for an association.
    #
    # @api public
    class PolymorphicIdentifier
      # @!attribute [r] as
      #   @return [Symbol] The name of the polymorphic association
      attr_reader :as

      # @!attribute [r] foreign_type_key
      #   @return [Symbol] The key for the foreign type
      attr_reader :foreign_type_key

      # @!attribute [r] foreign_key
      #   @return [Symbol] The key for the foreign ID
      attr_reader :foreign_key

      # @!attribute [r] foreign_type
      #   @return [String] The name of the foreign type
      attr_reader :foreign_type

      # Creates a new instance of PolymorphicIdentifier.
      #
      # @param as [Symbol] The name of the polymorphic association
      # @param source [Class, nil] The source class for the association
      # @yield [self] The instance of PolymorphicIdentifier
      # @return [PolymorphicIdentifier] The instance of PolymorphicIdentifier
      def initialize(as:, source: nil)
        @as = as
        @foreign_type_key = "#{as}_type".to_sym
        @foreign_key = "#{as}_id".to_sym
        @foreign_type = source.name.to_s if source

        yield self if block_given?
      end

      # Creates a new instance of PolymorphicIdentifier from the given parameters.
      #
      # @param source [Object] The source of the association
      # @param polymorphic [Boolean] Whether the association is polymorphic
      # @param as [Symbol] The name of the polymorphic association
      # @param name [Symbol] The name of the association
      # @return [PolymorphicIdentifier, nil] The instance of PolymorphicIdentifier or nil
      def self.[](source, polymorphic, as, name)
        case [polymorphic, as, name]
        in [true, _, Symbol] then new(as: name) # belongs_to :holder, polymorphic: true
        in [nil, Symbol, _] then new(as:, source:) # has_many :items, as: :
        else nil
        end
      end
    end
  end
end
