# frozen_string_literal: true

require 'active_record'

require_relative 'config'

ActiveRecord::Base.establish_connection(DB_URL)

require 'dry-monads'
require 'dry-struct'
require 'dry-types'
require 'dry-initializer'
require 'dry-equalizer'
require 'awesome_print'
AwesomePrint.irb!
AwesomePrint.pry!
# require_relative 'libs/sequel/core'

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem

loader.ignore(Pathname.new("#{__dir__}/libs"))
loader.ignore("#{__dir__}/config.rb")
loader.collapse(Pathname.new("#{__dir__}/resources/support"))
loader.ignore(Pathname.new("#{__dir__}/config.rb"))
loader.ignore(Pathname.new("#{__dir__}/bad_code_examples"))

if RESOURCES_ENV.test
  loader.push_dir(Pathname.new("#{__dir__}/spec"))
  loader.push_dir(Pathname.new("#{__dir__}/../spec/fixtures"))
  loader.collapse(Pathname.new("#{__dir__}/../spec/fixtures/models"))
end
loader.setup

module Resources
  module Types
    include Dry.Types()
  end
end
