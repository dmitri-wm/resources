module Resources
  module Associations
    class PolymorphicIdentifier
      attr_reader :as, :foreign_type_key, :foreign_key, :foreign_type

      def self.[](source, polymorphic, as, name)
        case [polymorphic, as, name]
        in [true, _, Symbol] then new(as: name) # belongs_to :holder, polymorphic: true
        in [nil, Symbol, _] then new(as:, source:) # has_many :items, as: :
        else nil
        end
      end

      # belongs_to :holder, polymorphic: true
      # name: :holder, as: nil
      #
      # has_many :items, as: :holder
      # name: items as: :holder
      def initialize(as:, source: nil)
        @foreign_type_key = "#{as}_type".to_sym
        @foreign_key = "#{as}_id".to_sym
        @foreign_type = source.name.to_s if source

        yield_self if block_given?
      end
    end
  end
end
