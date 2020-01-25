class CachePropertyTypes
  include CacheLoader

  def self.do_cache
    prop_types = Hash.new
    PropertyType.find_each do |type|
      prop_types[type.name] = type
    end

    prop_types
  end
end