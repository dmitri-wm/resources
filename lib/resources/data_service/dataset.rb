require 'dry/core/class_builder'

module Resources
  module DataService
    # Dataset class for handling data service operations
    # This class provides a flexible interface for working with various data services
    # that may have different interfaces and return types
    class Dataset < Resources::Dataset
      include AutoCurry

      FIRST_PAGE = 1
      DEFAULT_PER_PAGE = 10
      SUPPORTED_SERVICE_METHODS = %i[filter paginate order].freeze
      QUERY_METHODS = SUPPORTED_SERVICE_METHODS + %i[where exists? count]

      adapter :data_service

      # @!attribute [r] cache
      # @return [Loaded] The cache to be used for the dataset
      option :cache, optional: true

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
      option :order_by, default: -> { {} }

      # @!attribute [r] supported
      # @return [Array<Symbol>] The supported operations for this dataset
      option :supported, Types::Array.of(Types::Symbol.enum(*SUPPORTED_SERVICE_METHODS)), default: -> { [] }

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

      # Execute the service call and process the result
      # @return [Loaded] The processed result of the service call
      def call
        pipe(execute_service) do
          to_loaded >> after_load_hook
        end
      end

      # Convert the dataset to an array
      # @return [Array] The result of executing the service call
      def to_a
        call
      end

      # Apply conditions to the dataset
      # @param conditions [Hash] The conditions to apply
      # @return [Dataset] A new dataset instance with the applied conditions
      def filter(conditions)
        with(filters: { **filters, **conditions })
      end
      alias where filter

      def order(args)
        with(order_by: args)
      end

      def count
        call.count
      end

      def exists?
        paginate(per_page: 1, page: 1).count.positive?
      end

      # Apply pagination to the dataset
      # @param page [Integer] The page number
      # @param per_page [Integer] The number of items per page
      # @return [Dataset] A new dataset instance with pagination applied
      def paginate(page: 1, per_page: DEFAULT_PER_PAGE)
        with(page:, per_page:)
      end

      # Pluck a specific key from the dataset
      # @param key [Symbol, String] The key to pluck
      # @return [Array] An array of values for the specified key
      def pluck(...)
        to_a.pluck(...)
      end

      # Generate query options based on supported keys
      # @return [Proc] A proc that returns query options for the given keys
      def query_options
        proc { |*keys|
          {
            order: -> { { order_by: } },
            filter: -> { { filters: } },
            paginate: -> { { paginate: { page:, per_page: } } }
          }.values_at(*keys).map(&:call).reduce({}, :merge)
        }
      end

      # Execute the service call with the given options
      # @return [Object] The result of the service call
      def execute_service
        service_call[datasource, service_options]
      end

      # Generate service options based on supported query methods
      # @return [Hash] The service options
      def service_options
        query_options[*supported]
      end

      # Convert the raw data to a Loaded object
      # @param data [Object] The raw data
      # @return [Loaded] The loaded data
      curry def to_loaded(data)
        Loaded.new(data.map(&unified_hash))
      end

      curry def unified_hash(data)
        data.to_h.symbolize_keys
      end

      # Apply after load hooks to the data
      # @param data [Object] The loaded data
      # @return [Object] The processed data
      curry def after_load_hook(data)
        return data if non_supported.empty?

        after_load_actions.reduce(data) do |result, (method_name, args)|
          result.send(method_name, **args)
        end
      end

      # Generate after load actions based on non-supported query methods
      # @return [Hash] The after load actions
      def after_load_actions
        non_supported.zip(query_options[*non_supported].values).to_h.reject { |_, v| v.empty? }
      end

      # Determine the non-supported query methods
      # @return [Array<Symbol>] The non-supported query methods
      def non_supported
        SUPPORTED_SERVICE_METHODS - supported
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
