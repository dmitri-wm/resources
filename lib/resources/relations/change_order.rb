# frozen_string_literal: true
# domain: Change Events

module Resources
  module Relations
    class ChangeOrder < Adapters::Sql
      use_ar_model ::PotentialChangeOrder
    end
  end
end
