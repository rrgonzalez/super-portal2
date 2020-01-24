class DataFeed
  attr_accessor :properties, :users

  def initialize
    @properties = Array.new
    @users = Array.new
  end
end