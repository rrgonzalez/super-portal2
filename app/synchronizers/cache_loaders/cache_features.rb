class CacheFeatures
  include CacheLoader

  def self.do_cache
    features = Hash.new
    Feature.find_each do |feature|
      features[feature.name] = feature
    end

    features
  end
end