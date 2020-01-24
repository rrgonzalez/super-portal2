class EasyBrokerSynchronizer
  @@formatFeedParser

  def self.setParserStrategy(parserStrategy)
    @@formatFeedParser = parserStrategy
  end

  def self.synchronize
    logger = Rails.logger

    if @@formatFeedParser.nil?
      logger.error 'No Parser Strategy defined'
    else
      @@formatFeedParser.parse
    end
  end
end
