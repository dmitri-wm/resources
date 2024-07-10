class LineItem < ActiveRecord::Base
  belongs_to :holder, polymorphic: true
end
