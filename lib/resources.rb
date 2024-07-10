# frozen_string_literal: true

require 'active_record'

require_relative 'config'

ActiveRecord::Base.establish_connection(DB_URL)

require 'dry-monads'
require 'dry-struct'
require 'dry-types'
require 'dry-initializer'
require_relative 'libs/dry/transformer'
require_relative 'libs/sequel/core'

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.ignore(Pathname.new("#{__dir__}/sequel"))
loader.push_dir(Pathname.new("#{__dir__}/external"))
loader.push_dir(Pathname.new("#{__dir__}/external/models"))

loader.push_dir(Pathname.new("#{__dir__}/../spec/fixtures")) if RESOURCES_ENV.test

loader.setup

module Resources
  include Config

  class Error < StandardError; end
  # Your code goes here...
end
