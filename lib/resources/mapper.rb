class Mapper
  def self.map(resource, data)
    resource.new(data)
  end
end
