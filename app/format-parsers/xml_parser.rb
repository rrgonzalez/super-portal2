require 'open-uri'
require 'zlib'
require 'nokogiri'

class XmlParser
  include FormatParser
  @@logger = Rails.logger

  class << self

    def parse

      mutex = Mutex.new
      mutex.synchronize do

        @@logger.info 'STARTED: Downloading XML Feed Format file...'
        compressed = StringIO.new(open(ENV['XML_URL']).read)
        @@logger.info 'FINISHED: Downloading XML Feed Format file.'

        @@logger.info 'STARTED: Decompressing XML Feed Format file...'
        gz = Zlib::GzipReader.new(compressed)
        @@logger.info 'FINISHED: Decompressing XML Feed Format file.'

        @@logger.info 'STARTED: Parsing XML Feed Format file...'
        xml_doc = Nokogiri::Slop(gz.read)

        @@data_feed = get_data(xml_doc)
        @@logger.info 'FINISHED: Parsing XML Feed Format file.'

      end

      @@data_feed
    end

    private

    def get_data(xml_doc)
      begin
        prop_types = CachePropertyTypes.do_cache
        currencies = CacheCurrencies.do_cache
        features = CacheFeatures.do_cache

        data = DataFeed.new
        xml_doc.easybroker.agencies.children.each do |agency|
          company = get_agency_name(agency)

          ActiveRecord::Base.transaction do
            agency.properties.children.each do |it_prop|
              property = get_property(it_prop, prop_types, currencies, features, company)
              data.properties.append(property) unless property.nil?
            end
          end
        end

        return data
      rescue => e
        @@logger.error e.message
        @@logger.error e.backtrace

        @@logger.error 'There was an error parsing the XML Feed Format. It might be malformed.'
        nil
      end
    end

    def get_property(it_prop, prop_types, currencies, features, company)
      property = Property.new
      property.published = true
      property.external_id = it_prop.id if defined? it_prop.id
      property.title = it_prop.title if defined? it_prop.title
      property.description = get_property_description(it_prop)

      prop_type = it_prop.property_type.content if defined? it_prop.property_type
      property.property_type = prop_types[prop_type]

      property.bedrooms = it_prop.bedrooms if defined? it_prop.bedrooms
      property.bathrooms = it_prop.bathrooms if defined? it_prop.bathrooms
      property.parking_spaces = it_prop.parking_spaces.content if defined? it_prop.parking_spaces

      if defined? it_prop.location && defined? it_prop.location.city_area
        property.neighborhood = it_prop.location.city_area.content
      end

      set_operation_details(it_prop, property, currencies)

      # At this point all mandatory field should contain values
      # otherwise ignore this property
      return nil if incomplete?(property)

      set_images(it_prop, property)

      set_features(it_prop, property, features)

      set_user(it_prop, property, company)

      property
    end

    def incomplete?(property)
      incomplete = (property.title.nil? || property.title.empty? ||
                    property.description.nil? || property.description.empty? ||
                  !(property.rental || property.sale) ||
                    property.property_type.nil? || property.currency.nil? ||
                    property.external_id.nil? || property.external_id.empty? ||
                    property.neighborhood.nil? || property.neighborhood.empty?)
    end

    def set_operation_details(it_prop, property, currencies)
      return unless defined? it_prop.operation

      operation = it_prop.operation

      if defined? operation.price
        price = operation.price

        unless price.attribute('currency').nil? || price.attribute('currency').value.empty?
          aux = currencies[price.attribute('currency').value]

          if aux.nil?
            # Persisted because there are few currencies and they exist independently
            # from properties, so there is no risk of db inconsistence. !You need
            # to update relation with Property later.
            aux = Currency.new(code: price.attribute('currency').value)
            currencies[price.attribute('currency').value] = aux
          end

          property.currency = aux
        end

        if (price.attribute('unit').nil? ||
            price.attribute('unit').value.empty?) && !price.attribute('amount').nil?
          amount = price.attribute('amount').value.to_f
        end
      end

      return if operation.attribute('type').nil? || operation.attribute('type').value.empty?

      if operation.attribute('type').value == 'sale'
        property.sale = true
        property.sale_price = amount
      elsif operation.attribute('type').value == 'rental'
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

        if aux.nil?
          aux = Feature.new(name: feature.content)
          features[feature.content] = aux
        end

        property.features.append(aux)
      end
    end

    def set_images(it_prop, property)
      property.images = []
      return unless defined? it_prop.images

      it_prop.images.children.each_with_index do |image, order|
        image_obj = Image.new(url: image.content, order: order)
        property.images.append(image_obj)
      end
    end

    def set_user(it_prop, property, company)
      return unless (defined? it_prop.agent) && (defined? it_prop.agent.email)

      user = User.new
      user.email = it_prop.agent.email.content

      it_prop.agent.children.each do |node|
        if node.name == 'name'
          # If would have more time I would split this node content
          # to separate first_name from last_name
          user.first_name = node.content
          break
        end
      end

      user.company = company
      user.phone = it_prop.agent.cell if defined? it_prop.agent.cell

      property.user = user
    end
  end
end