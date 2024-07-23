module Resources
  # A helper module that adds data-proxy behavior to an array-like object
  #
  # @see EnumerableDataset
  #
  # @api public
  module ArrayDataset
    attr_reader :data

    include Memoizable

    # Extends the class with data-proxy behavior
    #
    # @api private
    def self.included(klass)
      klass.class_eval do
        extend Dry::Initializer

        param :data
      end
    end

    def row_proc
      ->(row) { row }
    end

    def self.forward(*methods)
      methods.each do |method_name|
        define_method(method_name) do |*args, &block|
          response = data.public_send(method_name, *args, &block)

          if response.equal?(data)
            self
          elsif response.is_a?(data.class)
            self.class.new(response)
          else
            response
          end
        end
      end
    end

    def to_a = self

    def each(&block)
      return to_enum unless block

      data.each { |tuple| block.call(row_proc.call(tuple)) }
    end

    %i[
      chunk collect collect_concat drop_while find_all flat_map
      grep map reject select sort sort_by take_while
    ].each do |method|
      define_method(method) do |*args, &block|
        return to_enum unless block

        self.class.new(super(*args, &block), **options)
      end
    end

    forward(
      :*, :+, :-, :compact, :compact!, :flatten, :flatten!, :length, :pop,
      :reverse, :reverse!, :sample, :size, :shift, :shuffle, :shuffle!,
      :slice, :slice!, :sort!, :uniq, :uniq!, :unshift, :values_at, :take
    )

    %i[
      map! combination cycle delete_if keep_if permutation reject!
      select! sort_by!
    ].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          return to_enum unless block
          self.class.new(data.send(:#{method}, *args, &block), **options)
        end
      RUBY
    end

    def options
      self.class.dry_initializer.definitions.values.each_with_object({}) do |item, obj|
        obj[item.target] = instance_variable_get(item.ivar)
      end
    end

    memoize :options
  end
end
