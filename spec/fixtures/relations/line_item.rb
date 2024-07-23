module Relations
  class LineItem < Resources::Adapters::Ar
    dataset ::LineItem

    def holders = LineItemHolders.build(holders_set, **options)

    def holders_set = holder_ids.reduce({}, &type_map)

    def type_map =->(map, ids) { (map[ids.last] ||= []) << ids.first }

    def holder_ids = pluck(:holder_id)
  end
end