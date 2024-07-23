# frozen_string_literal: true

# domain: Change Events

module Relations
  module ChangeOrders
    class MultiTier < Base
      def batches
        ChangeOrders::Batches.new(context:, type:).where(id: batch_ids)
      end

      def batch_ids
        pluck(:batch_id)
      end
    end
  end
end
