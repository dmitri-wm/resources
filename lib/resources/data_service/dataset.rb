require 'dry/core/class_builder'

module Resources
  module DataService
    # Dataset class for handling data service operations
    # This class provides a flexible interface for working with various data services
    # that may have different interfaces and return types
    class Dataset < Resources::Dataset
      extend Initializer
      FIRST_PAGE = 1
      DEFAULT_PER_PAGE = 10

      adapter :data_service

      # @!attribute [r] service_call
      # @return [Proc] The service call to be executed
      option :service_call

      # @!attribute [r] filters
      # @return [Hash] The filters to be applied to the dataset
      option :filters, default: -> { {} }

      # @!attribute [r] page
      # @return [Integer, nil] The current page number for pagination
      option :page, default: -> { nil }

      # @!attribute [r] per_page
      # @return [Integer, nil] The number of items per page for pagination
      option :per_page, default: -> { nil }

      # @!attribute [r] order
      # @return [Hash] The ordering criteria for the dataset
      option :order, default: -> { {} }

      # @!attribute [r] supported
      # @return [Array<Symbol>] The supported operations for this dataset
      option :supported, Array.of(Types::Symbol.enum(:order, :filter, :paginate)), default: -> { [] }

      QUERY_METHODS = %i[where filter paginate order].freeze

      # Apply conditions to the dataset
      # @param conditions [Hash] The conditions to apply
      # @return [Dataset] A new dataset instance with the applied conditions
      def where(conditions)
        with(filters: { **filters, **conditions })
      end
      alias filter where

      # Apply pagination to the dataset
      # @param page [Integer] The page number
      # @param per_page [Integer] The number of items per page
      # @return [Dataset] A new dataset instance with pagination applied
      def paginate(page: 1, per_page: 10)
        with(page:, per_page:)
      end

      # Pluck a specific key from the dataset
      # @param key [Symbol, String] The key to pluck
      # @return [Array] An array of values for the specified key
      def pluck(key)
        preload.pluck(key)
      end

      # Create a new instance of the dataset, potentially with a custom class
      # @param datasource [Object] The data source
      # @param options [Hash] Additional options for dataset creation
      # @return [Dataset] A new dataset instance
      def self.new(datasource, **options)
        if additional_setup?(options)
          fetch_custom_class(**options.delete(:config)).new(datasource, **options)
        else
          super(datasource, **options)
        end
      end

      # Convert the dataset to an array
      # @return [Array] The result of executing the service call
      def to_a
        service_call.call(datasource, options: options)
      end

      # Preload the dataset
      # @return [Loaded] A new Loaded instance with the preloaded data
      def preload
        Loaded.new(to_a)
      end

      # Fetch a custom class for the dataset
      # @param relation_name [Symbol] The name of the relation
      # @param dataset_config [Proc] The configuration for the dataset
      # @return [Class] A dynamically created custom dataset class
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

      # Check if additional setup is required
      # @param options [Hash] The options hash
      # @return [Boolean] True if additional setup is needed, false otherwise
      def self.additional_setup?(options)
        options[:config].present?
      end
    end
  end
end
