module Resources
  # A helper module that adds data-proxy behavior to an array-like object
  #
  # @see EnumerableDataset
  #
  # @api public
  class ArrayDataset
    extend Initializer

    param :data

    # Performs an array-based join operation
    #
    # @param target [ArrayDataset] The target dataset (default: self)
    # @param source [ArrayDataset] The source dataset to join with
    # @param key_map [Hash] A hash mapping source keys to target keys
    # @return [ArrayDataset] A new ArrayDataset with the joined data
    def joins_array(target = self, source, key_map)
      ((source_key, target_key)) = key_map.to_a
      target_array = target.to_a
      source_array = source.to_a

      joined_array = target_array.flat_map do |target_item|
        matching_sources = source_array.select { |source_item| source_item[source_key] == target_item[target_key] }
        matching_sources.map { |source_item| target_item.merge(source_item) }
      end

      ArrayDataset.new(joined_array)
    end

    # Performs a join operation with another dataset
    #
    # @param args [Array] Arguments for the join operation
    # @return [ArrayDataset] A new ArrayDataset with the joined data
    def join(*args)
      left, right = args.size > 1 ? args : [self, args.first]

      join_map = left.each_with_object({}) do |tuple, h|
        others = right.to_a.find_all { |t| (tuple.to_a & t.to_a).any? }
        (h[tuple] ||= []).concat(others)
      end

      tuples = left.flat_map do |tuple|
        join_map[tuple].map { |other| tuple.merge(other) }
      end

      self.class.new(tuples, **options)
    end

    # Restricts the dataset based on given criteria
    #
    # @param criteria [Hash, nil] The criteria to restrict the dataset
    # @yield [tuple] A block to filter tuples
    # @return [Array] An array of tuples that match the criteria or pass the block
    def restrict(criteria = nil, &block)
      return find_all(&block) unless criteria

      find_all do |tuple|
        criteria.all? do |k, v|
          case v
          when Array then v.include?(tuple[k])
          when Regexp then tuple[k].match(v)
          else tuple[k].eql?(v)
          end
        end
      end
    end
    alias filter restrict
    alias where restrict

    # Projects the dataset to include only specified attributes
    #
    # @param names [Array<Symbol>] The names of the attributes to include
    # @return [Array] An array of tuples with only the specified attributes
    def select(*names)
      map { |tuple| tuple.select { |key| names.include?(key) } }
    end

    # Orders the dataset based on specified fields
    #
    # @param fields [Array<Symbol>] The fields to order by
    # @return [Array] An ordered array of tuples

    def order(*args)
      nils_first_setting, nested = args.last.delete(:options).values_at(:nils_first, :nested) if args.last.is_a?(Hash) && args.last.key?(:options)
      args.pop if args.last.empty?
      sort do |a, b|
        args.reduce(0) do |result, criterion|
          break result if result != 0

          key, direction = extract_order_info(criterion)
          nils_first = criterion.is_a?(Hash) && criterion.key?(:nils_first) ? criterion[:nils_first] : nils_first_setting

          val_a = extract_value(a, key, nested)
          val_b = extract_value(b, key, nested)

          compare_values(val_a, val_b, direction, nils_first)
        end
      end
    end

    def extract_order_info(criterion)
      case criterion
      when Symbol
        [criterion, :asc]
      when Hash
        criterion.first
      else
        raise ArgumentError, "Invalid order criterion: #{criterion}"
      end
    end

    def extract_value(tuple, key, nested)
      if nested
        tuple.dig(*key.to_s.split('.').map(&:to_sym))
      else
        tuple[key]
      end
    end

    def compare_values(val_a, val_b, direction, nils_first)
      if val_a.nil? || val_b.nil?
        return 0 if val_a.nil? && val_b.nil?
        return val_a.nil? ? -1 : 1 if nils_first

        return val_b.nil? ? -1 : 1
      end

      comparison = (val_a <=> val_b)
      direction == :desc ? -comparison : comparison
    end

    # Inserts a tuple into the dataset
    #
    # @param tuple [Hash] The tuple to insert
    # @return [ArrayDataset] The dataset with the inserted tuple
    def insert(tuple)
      data << tuple
      self
    end
    alias << insert

    # Deletes a tuple from the dataset
    #
    # @api public
    # @param tuple [Hash] The tuple to delete
    # @return [ArrayDataset] The dataset with the tuple removed
    def delete(tuple)
      data.delete(tuple)
      self
    end

    def ==(other)
      data == (other.is_a?(ArrayDataset) ? other.data : other)
    end

    def inspect
      "<#{self.class}:#{data}>"
    end
    alias to_s inspect

    def to_a = data

    def row_proc
      ->(row) { row }
    end

    def each(&block)
      return to_enum unless block

      data.each { |tuple| block.call(row_proc.call(tuple)) }
    end

    def paginate(page:, per_page:)
      return self if [page, per_page].any?(&:nil?)

      offset = (page - 1) * per_page
      last_index = offset + per_page < size ? offset + per_page : size

      values_at(offset...last_index)
    end

    def pluck(*keys)
      if keys.size == 1
        key = keys.first
        data.map { |item| item[key] }
      else
        data.map { |item| item.values_at(*keys) }
      end
    end

    def with(datasource)
      self.class.new(datasource)
    end

    %i[size first last size values_at].each do |method_name|
      define_method(method_name) do |*args, &block|
        response = data.public_send(method_name, *args, &block)

        if response.equal?(data)
          self
        elsif response.is_a?(data.class)
          with(response)
        else
          response
        end
      end
    end
    alias count size

    %i[
      chunk collect collect_concat drop_while find_all flat_map
      grep map reject sort sort_by take_while
      map! combination cycle delete_if keep_if permutation reject!
      sort_by! each_with_object
    ].each do |method|
      define_method(method) do |*args, &block|
        return to_enum unless block

        with(data.public_send(method, *args, &block))
      end
    end
  end
end
