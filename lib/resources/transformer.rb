module Resources
  # @api public
  class Transformer < Dry::Transformer::Pipe
    def self.map(&block)
      define! do
        map_array(&block)
      end
    end
  end
end
