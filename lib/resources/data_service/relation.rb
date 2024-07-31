module Resources
  module DataService
    # Relation class for handling data service operations
    # This class provides a flexible interface for working with various data services
    # and manages the relationship between services and datasets
    class Relation < Resources::Relation
      adapter :data_service

      class << self
        attr_accessor :data_service_class

        # Retrieve the data service class or raise an error if not set
        # @return [Class] The data service class
        # @raise [NotImplementedError] If data_service_class is not set
        def data_service
          data_service_class or raise NotImplementedError
        end

        # Set the data service class to be used
        # @param service_class [Class] The data service class to be used
        def use_data_service(service_class)
          self.data_service_class = service_class
        end
      end

      # Define the dataset class to be used
      # Usage: dataset_class MyCustomDataset
      defines :dataset_class
      dataset_class Dataset

      # Default service call implementation
      # This can be overridden in subclasses for custom data fetching logic
      # Usage:
      #   service_call do |data_service_instance, options|
      #     data_service_instance.find_some(filter: options[:filters]).value!
      #   end
      defines :service_call, :dataset_config, :supports
      service_call ->(dataset) { dataset.datasource.to_a }

      # Define supported query methods
      # Usage: supports :paginate, :filter, :order

      defines :supports, type: Types::Array.of(Types::Symbol.enum(:order, :filter, :paginate))
      supports []

      # @!attribute [r] dataset
      #   @return [Dataset] The dataset instance
      option :dataset, default: -> { initialize_dataset }

      delegate :service_call, :dataset_class, :dataset_config, :relation_name, :data_service, to: :class
      delegate :pluck, :count, :exists?, to: :dataset
      forward(*Dataset::QUERY_METHODS, to: :dataset)

      # Convert a record to a struct
      # @param data [Hash] The record to be converted
      # @return [AutoStruct] The record converted to an AutoStruct
      def to_struct(data)
        AutoStruct.new(data)
      end

      def graph
        Graph.new(relation: self, meta: { root: true })
      end
      delegate :left_outer_join, :joins, :join, :join_by_type, to: :graph

      def join!(relation:, join_keys:, name:, type: :inner)
        with(dataset: dataset.join(dataset: relation.dataset, join_keys:, type:, name:))
      end

      # @return [Loaded] the loaded instance
      def pf_keys_fetch_prepare
        with(dataset: dataset.to_a)
      end

      # Initialize the dataset
      # This method creates a new dataset instance with the configured data service and options
      # @return [Dataset] A new dataset instance
      def initialize_dataset
        dataset_class.new(
          data_service.new(context: context),
          **Hash(custom_config),
          service_call:
        )
      end

      # Generate custom configuration for the dataset
      # This method is used to pass relation-specific configuration to the dataset
      # Usage:
      #   dataset_config do
      #     param :additional_param
      #     option :additional_option
      #
      #     def override_any_method
      #       # Custom implementation
      #     end
      #   end
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
