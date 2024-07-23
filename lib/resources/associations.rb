 # frozen_string_literal: true

module Resources
  module Associations
    def self.included(base)
      base.include(AssociationsDSL)
    end
  end
end