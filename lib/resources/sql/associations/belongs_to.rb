# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      class BelongsTo < ::Resources::Associations::BelongsTo
        include Associations::Core

        def call(target: self.target)
          target.join(relation: source, join_keys: { target_key => source_key })
        end

        def join(type, source = self.source, target = self.target)
          source.__send__(:join, type, target, { source_key => target_key })
        end
      end
    end
  end
end
