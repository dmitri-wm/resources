# frozen_string_literal: true

module Resources
  class Relation
    module ClassInterface
      DEFAULT_DATASET_PROC = ->(*) { self }.freeze

      def dataset(&block)
        if defined?(@dataset)
          @dataset
        else
          @dataset = block || DEFAULT_DATASET_PROC
        end
      end

      def view(name, &block)
        define_method name do
          instance_exec(&block)
        end
      end

      def name
        super || superclass.name
      end
    end
  end
end
