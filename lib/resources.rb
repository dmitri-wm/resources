# frozen_string_literal: true

require "active_record"
require "dry-monads"
require "dry-struct"
require "dry-types"
require "dry-initializer"
require_relative "external/active_support/concern"
require_relative "external/memoizer"
require_relative "resources/sequel/core"
require_relative "resources/version"
require_relative "resources/config"
require_relative "resources/entities"
require_relative "resources/relations"

module Resources
  include Config

  class Error < StandardError; end
  # Your code goes here...
end
