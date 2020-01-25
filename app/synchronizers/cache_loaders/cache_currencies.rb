class CacheCurrencies
  include CacheLoader

  def self.do_cache
    currencies = Hash.new
    Currency.find_each do |currency|
      currencies[currency.code] = currency
    end

    currencies
  end
end