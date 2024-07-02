# frozen_string_literal: true
# domain: Change Events

module Financials
  module Private
    module ChangeEvents
      module Resources
        module Relations
          module Adapters
            module Lib
              module UseSortingService
                extend ActiveSupport::Concern

                included do
                  class << self
                    attr_accessor :sorting_service
                  end
                end

                class_methods do
                  def use_sorting_service(service)
                    self.sorting_service = service
                  end
                end

                def sorting_service
                  self.class.sorting_service
                end

                def update_sort(*args)
                  tap { sort_params.concat(args) }
                end
                alias_method :sort, :update_sort

                def sort_params
                  @sort_params ||= []
                end

                def sort_data
                  ->(data) { sort_params.presence ? sorting_service.call(data, sort_params, context) : data }
                end
              end
            end
          end
        end
      end
    end
  end
end
