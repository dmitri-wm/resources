module Resources
  module DataService
    class Relation < Resources::Relation
      class << self
        attr_accessor :data_service_class

        def data_service
          data_service_class or raise NotImplementedError
        end

        def use_data_service(service_class)
          self.data_service_class = service_class
        end
      end
      defines :dataset_class
      dataset_class Dataset

      defines :service_call, :dataset_config
      option :dataset, default: -> { initialize_dataset }

      service_call ->(dataset) { dataset.datasource.to_a }

      delegate :service_call, :dataset_class, :dataset_config, :relation_name, :data_service, to: :class

      private

      def initialize_dataset
        dataset_class.new(
          data_service.new(context: context),
          **Hash(custom_config),
          service_call:
        )
      end

      def custom_config
        return if dataset_config.nil?

        {
          config:
            {
              relation_name:,
              dataset_config:
            }
        }
      end
    end
  end
end
