class EasyBrokerSynchronizer
  @@formatFeedParser
  @@logger = Rails.logger

  def self.setParserStrategy(parserStrategy)
    @@formatFeedParser = parserStrategy
  end

  class << self
    def synchronize
      if @@formatFeedParser.nil?
        @@logger.error 'No Parser Strategy defined'
      else
        begin
          @@data_feed = @@formatFeedParser.parse

          @@logger.info "Found #{@@data_feed.properties.count} valid properties on Format Feed"
        rescue => e
          @@logger.error e.message
          @@logger.error e.backtrace

          @@logger.error "Couldn't execute synchronization. An unexpected error ocurred"
        end
      end
    end

    #private
    #
    #def do_sync
    #  cache_currencies
    #  cache_features
    #end

  end
end
