class DataFeed
  attr_accessor :properties, :users, :images

  def initialize
    @properties = Array.new
    @users = Array.new
    @images = Hash.new { |h, k| h[k] = [] }
  end
end