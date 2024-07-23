module Resources
  module Sql
    # ArrayDataset class for handling array-based datasets in SQL operations
    # @api public
    class ArrayDataset
      include Resources::ArrayDataset

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
      def order(*fields)
        nils_first = fields.pop[:nils_first] if fields.last.is_a?(Hash)

        sort do |a, b|
          fields # finds the first difference between selected fields of tuples
            .map { |n| __compare__ a[n], b[n], nils_first }
            .detect(-> { 0 }) { |r| r != 0 }
        end
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

      private

      # Compares two values, handling nil values based on the nils_first parameter
      #
      # @param a [Object] The first value to compare
      # @param b [Object] The second value to compare
      # @param nils_first [Boolean] Whether nil values should be considered first
      # @return [Integer] The comparison result (-1, 0, or 1)
      def __compare__(a, b, nils_first)
        return a <=> b unless a.nil? ^ b.nil?

        nils_first ^ b.nil? ? -1 : 1
      end
    end
  end
end
