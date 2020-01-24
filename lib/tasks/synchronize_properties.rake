namespace :synchronize_properties do
  desc 'Downloads and synchronizes properties from external portals'
  task all: :environment do
    # Set the concrete Parser Strategy
    EasyBrokerSynchronizer.setParserStrategy(XmlParser)
    EasyBrokerSynchronizer.synchronize
  end
end
