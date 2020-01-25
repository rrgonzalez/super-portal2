class CacheImages
  include CacheLoader

  def self.do_cache
    images = Hash.new
    Image.find_each do |image|
      images[image.url] = image
    end

    images
  end
end