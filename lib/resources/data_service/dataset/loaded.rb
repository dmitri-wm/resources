# frozen_string_literal: true

module Resources
  module DataService
    class Dataset
      class Loaded < ArrayDataset
        def to_sql(association_name)
          "SELECT * FROM json_to_recordset('#{data.to_json}') AS #{association_name}(#{column_definitions(data.first)})"
        end

        def column_definitions(sample_data)
          sample_data.map { |k, v| "#{k} #{sql_type(v)}" }.join(', ')
        end

        def sql_type(value)
          case value
          when Integer then 'INTEGER'
          when Float then 'FLOAT'
          when Time, Date then 'TIMESTAMP'
          else 'TEXT'
          end
        end

        def datasource
          self
        end

        def join(dataset:, join_keys:, type:, name:)
          ((right_key, left_key)) = join_keys.to_a
          data_to_join = dataset.where(right_key => pluck(left_key)).to_a
          combines_array(data_to_join, join_keys, type, name)
        end
      end
    end
  end
end
