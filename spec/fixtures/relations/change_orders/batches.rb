# frozen_string_literal: true

# domain: Change Events

module Relations
  module ChangeOrders
    class Batches < Base
      defines :dataset, ->(_context, type) { ::Financials::Public::ChangeOrders::BatchService.build(type) }
    end
  end
end
