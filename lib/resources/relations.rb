# frozen_string_literal: true

# domain: Change Events

require_relative "relations/adapters/lib/dependencies"
require_relative "relations/adapters/lib/use_sorting_service"
require_relative "relations/adapters/lib/use_entity_mapper"
require_relative "relations/adapters/lib/where_queries"
require_relative "relations/adapters/lib/pagination"
require_relative "relations/adapters/lib/selectable_fields"
require_relative "relations/adapters/lib/array_conversion"
require_relative "relations/adapters/lib/transformation"
require_relative "relations/adapters/lib/associations"
require_relative "relations/adapters/lib/use_filters_service"
require_relative "relations/adapters/lib/sql/use_active_record"
require_relative "relations/adapters/base"
require_relative "relations/adapters/sql"

module Resources
  module Relations
  end
end
