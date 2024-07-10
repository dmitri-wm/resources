class PotentialChangeOrder < ActiveRecord::Base
  belongs_to :contract, optional: true
end
