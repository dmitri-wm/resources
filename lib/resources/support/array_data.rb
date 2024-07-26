module Resources
  # A helper module that adds data-proxy behavior to an array-like object
  #
  # @see EnumerableDataset
  #
  # @api public
  module ArrayData
    attr_reader :data

    def self.included(klass)
      klass.class_eval do
        extend Initializer

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

    forward(
      :*, :+, :-, :compact, :compact!, :flatten, :flatten!, :length, :pop,
      :reverse, :reverse!, :sample, :size, :shift, :shuffle, :shuffle!,
      :slice, :slice!, :sort!, :uniq, :uniq!, :unshift, :values_at, :take, :include?
    )
  end
end
