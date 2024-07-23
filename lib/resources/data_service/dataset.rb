require 'dry/core/class_builder'

module Resources
  module DataService
    class Dataset < Resources::Dataset
      adapter :data_service

      option :service_call
      option :filters, default: -> { {} }
      option :page, default: -> { 1 }
      option :per_page, default: -> { 10 }
      option :sort, default: -> { {} }

      def self.new(datasource, **options)
        if additional_setup?(options)
          fetch_custom_class(**options.delete(:config)).new(datasource, **options)
        else
          super(datasource, **options)
        end
      end

      def to_a
        instance_eval(&service_call)
      end

      # @param relation_name [Symbol]
      # @param dataset_config [Proc]
      # @return [Class]
      def self.fetch_custom_class(relation_name:, dataset_config:)
        custom_dataset_class_name = relation_name.to_s.classify

        Dry::Core::ClassBuilder.new(
          name: custom_dataset_class_name,
          parent: self,
          namespace: self
        ).call do |klass|
          klass.instance_eval(&dataset_config)

          const_get("::#{custom_dataset_class_name}").dataset klass
          const_get("::#{custom_dataset_class_name}").dataset_config
        end
      end

      def self.additional_setup?(options)
        options[:config].present?
      end

      def where(conditions)
        with(filters: { **filters, **conditions })
      end
      alias filter where
    end
  end
end
