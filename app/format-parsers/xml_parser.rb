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
      result
    end

    private

    def get_data(xml_doc)
      begin
        prop_types = cache_property_types
        currencies = cache_currencies
        features = cache_features

        data = DataFeed.new
        xml_doc.easybroker.agencies.children.each do |agency|
          company = get_agency_name(agency)

          agency.properties.children.each do |it_prop|
            property = get_property(it_prop, prop_types, currencies, features)
            data.properties.append(property)
          end

          puts data.properties.count
        end
      rescue => e
        @@logger.error e.message
        @@logger.error e.backtrace

        @@logger.error 'There was an error parsing the XML Feed Format. It might be malformed.'
        nil
      end
    end

    def get_property(it_prop, prop_types, currencies, features)
      property = Property.new
      property.external_id = it_prop.id if defined? it_prop.id
      property.title = it_prop.title if defined? it_prop.title
      property.description = get_property_description(it_prop)

      prop_type = it_prop.property_type.content if defined? it_prop.property_type
      property.property_type = prop_types[prop_type]

      property.bedrooms = it_prop.bedrooms if defined? it_prop.bedrooms
      property.bathrooms = it_prop.bathrooms if defined? it_prop.bathrooms
      property.parking_spaces = it_prop.parking_spaces.content if defined? it_prop.parking_spaces
      property.neighborhood = it_prop.city_area.content if defined? it_prop.city_area

      set_operation_details(it_prop, property, currencies)

      # images

      set_features(it_prop, property, features)

      property
    end

    def set_operation_details(it_prop, property, currencies)
      return unless defined? it_prop.operation

      operation = it_prop.operation

      if defined? operation.price
        price = operation.price

        unless price.attribute('currency').nil? || price.attribute('currency').value.empty?
          aux = currencies[price.attribute('currency')]
          aux = Currency.create(code: price.attribute('currency'))
          currencies[price.attribute('currency')] = aux
          property.currency = aux
        end

        if (price.attribute('unit').nil? ||
            price.attribute('unit').value.empty?) && !price.attribute('amount').nil?
          amount = price.attribute('amount').value.to_f
        end
      end

      if operation.content == 'sale'
        property.sale = true
        property.sale_price = amount
      elsif operation.content == 'rent'
        property.rental = true
        property.rent = amount
      end
    end

    def get_agency_name(agency)
      agency.children.each do |node|
        if node.name == 'name'
          return node.content
        end
      end
      return ''
    end

    def get_property_description(property)
      property.children.each do |node|
        if node.name == 'description'
          return node.content
        end
      end
      return ''
    end

    def set_features(it_prop, property, features)
      return unless defined? it_prop.features

      it_prop.features.children.each do |feature|
        aux = features[feature.content]

        # No need to worry for db insertions because there are few features
        aux = Feature.create(name: feature.content) if aux.nil?

        features[feature.content] = aux

        property.features.append(aux)
      end
    end

    def cache_property_types
      prop_types = Hash.new
      PropertyType.find_each do |type|
        prop_types[type.name] = type
      end

      return prop_types
    end

    def cache_currencies
      currencies = Hash.new
      Currency.find_each do |currency|
        currencies[currency.code] = currency
      end

      return currencies
    end

    def cache_features
      features = Hash.new
      Feature.find_each do |feature|
        features[feature.name] = feature
      end

      return features
    end
  end
end