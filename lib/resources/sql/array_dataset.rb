module Resources
  module Sql
    class ArrayDataset
      include Resources::ArrayDataset

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

      def project(*names)
        map { |tuple| tuple.select { |key| names.include?(key) } }
      end

      def order(*fields)
        nils_first = fields.pop[:nils_first] if fields.last.is_a?(Hash)

        sort do |a, b|
          fields # finds the first difference between selected fields of tuples
            .map { |n| __compare__ a[n], b[n], nils_first }
            .detect(-> { 0 }) { |r| r != 0 }
        end
      end

      def insert(tuple)
        data << tuple
        self
      end
      alias << insert

      # @api public
      def delete(tuple)
        data.delete(tuple)
        self
      end

      private

      def __compare__(a, b, nils_first)
        return a <=> b unless a.nil? ^ b.nil?

        nils_first ^ b.nil? ? -1 : 1
      end
    end
  end
end
