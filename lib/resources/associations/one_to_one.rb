# frozen_string_literal: true

require 'rom/associations/one_to_many'

module Resources
  module Associations
    # Abstract one-to-one association type
    #
    # @api public
    class HasOne < BelongsTo
    end
  end
end
