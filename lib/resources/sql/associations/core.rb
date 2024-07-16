# frozen_string_literal: true

module Resources
  module Sql
    module Associations
      module SelfRef
        def self.included(klass)
          super
          klass.memoize :join_keys, :source_table, :source_alias, :source_attr, :target_attr
        end

        # @api public
        def join_keys
          { source_key => target_key }
        end
      end
    end
  end
end
