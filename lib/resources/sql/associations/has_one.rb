# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      class HasOne < BelongsTo
        def foreign_key
          definition.foreign_key || "#{source.name}_id"
        end
      end
    end
  end
end
