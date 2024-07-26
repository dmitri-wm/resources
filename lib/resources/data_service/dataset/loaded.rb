# frozen_string_literal: true

module Resources
  module DataService
    class Dataset
      class Loaded < ArrayDataset
        def limit(n)
          self.class.new(data[0...n])
        end

        def offset(n)
          self.class.new(data[0...n])
        end

        def paginate(page:, per_page:)
          return self if [page, per_page].any?(&:nil?)

          offset((page - 1) * per_page).limit(per_page)
        end

        def pluck(*keys)
          if keys.size == 1
            key = keys.first
            data.map { |item| item[key] }
          else
            data.map { |item| item.values_at(*keys) }
          end
        end
      end
    end
  end
end
