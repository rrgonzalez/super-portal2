require 'open-uri'
require 'zlib'
require 'nokogiri'

class XmlParser
  include FormatParser
  @@logger = Rails.logger

  class << self

    def parse
      @@logger.info 'STARTED: Downloading XML Feed Format file...'
      compressed = StringIO.new(open(ENV['XML_URL']).read)
      @@logger.info 'FINISHED: Downloading XML Feed Format file.'

      @@logger.info 'STARTED: Decompressing XML Feed Format file...'
      gz = Zlib::GzipReader.new(compressed)
      @@logger.info 'FINISHED: Decompressing XML Feed Format file.'

      @@logger.info 'STARTED: Parsing XML Feed Format file...'
      xml_doc = Nokogiri::Slop(gz.read)

      result = get_data(xml_doc)
      @@logger.info 'FINISHED: Parsing XML Feed Format file.'
      return result
    end

    private

    def get_data(xml_doc)
      begin
        data = DataFeed.new
        xml_doc.easybroker.agencies.children.each do |agency|
          agency_name = '-'
          agency.children.each do |node|
            if node.name == 'name'
              agency_name = node.content
              break
            end
          end


        end
      rescue
        @@logger.error 'There was an error parsing the XML Feed Format. It might be malformed.'
      end
    end
  end
end