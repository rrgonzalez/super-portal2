require 'set'

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
          data_feed = @@formatFeedParser.parse

          @@logger.info "Found #{data_feed.properties.count} valid properties on Format Feed"

          do_sync(data_feed)
        rescue => e
          @@logger.error e.message
          @@logger.error e.backtrace

          @@logger.error "Couldn't execute synchronization. An unexpected error ocurred"
        end
      end
    end

    private

    def do_sync(data_feed)
      @@logger.info 'STARTED: Synchronizing memory data with db data...'

      users = CacheUsers.do_cache
      currencies = CacheCurrencies.do_cache
      features = CacheFeatures.do_cache
      property_types = CachePropertyTypes.do_cache
      images_cache = CacheImages.do_cache

      no_prop_users = Hash.new
      users.each do |user|
        no_prop_users[user.email] = user.id
      end

      curr_prop_ids = curr_properties_ids
      data_feed.properties.each do |new_prop|
        ActiveRecord::Base.transaction do

          if curr_prop_ids.include?(new_prop.external_id)
            different = false
            changing_fields = Hash.new
            curr_prop_ids.delete(new_prop.external_id)

            curr_prop = Property.where(external_id: new_prop.external_id).take
            different ||= compare_single_fields(curr_prop, new_prop, changing_fields)

            different ||= compare_user(curr_prop, new_prop, changing_fields, users, no_prop_users)

            different ||= compare_currency(curr_prop, new_prop, changing_fields, currencies)

            different ||= compare_property_type(curr_prop, new_prop, changing_fields, property_types)

            different ||= compare_features(curr_prop, new_prop, changing_fields, features)

            different ||= compare_images(curr_prop, new_prop, changing_fields)

            if different
              curr_prop.update(changing_fields)
            end
          else
            # New Property
            new_prop.images&.each do |new_image|
              image = Image.where(url: new_image.url).take
              Image.destroy(image.id) unless image.nil?

              new_image.save
            end

            new_prop.features&.each do |new_feature|
                new_feature = get_feature(features, new_feature, new_prop)
              end

            new_prop.property_type = get_property_type(new_prop.property_type, property_types)

            new_prop.currency = get_currency(currencies, new_prop.currency)

            unless new_prop.user.nil?
              new_prop.user = get_user(new_prop.user, users)
              no_prop_users.delete(new_prop.user.email)
            end

            new_prop.save
          end
        end
      end

      @@logger.info 'STARTED: Erasing corresponding users...'
      no_prop_users.each_value do |user_id|
        User.destroy(user_id)
      end
      @@logger.info 'FINISHED: Erasing corresponding users.'

      @@logger.info 'STARTED: Unpublishing corresponding properties...'
      curr_prop_ids.each_value do |prop_id|
        Property.update(prop_id, published: false)
      end
      @@logger.info 'FINISHED: Unpublishing corresponding properties.'

      @@logger.info 'FINISHED: Synchronizing memory data with db data!'
    end

    def curr_properties_ids
      curr_prop_ids = Hash.new
      Property.find_each do |prop|
        curr_prop_ids[prop.external_id] = prop.id
      end

      curr_prop_ids
    end

    def curr_property_features(property)
      curr_prop_features_names = Set.new
      Feature.where(property: property).each do |feature|
        curr_prop_features_names.add(feature.name)
      end

      curr_prop_features_names
    end

    def curr_property_images(property)
      curr_prop_images_urls = Hash.new
      Image.where(property: property).each do |image|
        curr_prop_images_urls[image.url] = image
      end

      curr_prop_images_urls
    end

    def compare_single_fields(curr_prop, new_prop, changing_fields)
      different = false

      if new_prop.title != curr_prop.title
        different = true
        changing_fields[:title] = new_prop.title
      end

      if new_prop.description != curr_prop.description
        different = true
        changing_fields[:description] = new_prop.description
      end

      if new_prop.rental != curr_prop.rental
        different = true
        changing_fields[:rental] = new_prop.rental
      end

      if new_prop.rent != curr_prop.rent
        different = true
        changing_fields[:rent] = new_prop.rent
      end

      if new_prop.sale != curr_prop.sale
        different = true
        changing_fields[:sale] = new_prop.sale
      end

      if new_prop.sale_price != curr_prop.sale_price
        different = true
        changing_fields[:sale_price] = new_prop.sale_price
      end

      if new_prop.bedrooms != curr_prop.bedrooms
        different = true
        changing_fields[:bedrooms] = new_prop.bedrooms
      end

      if new_prop.bathrooms != curr_prop.bathrooms
        different = true
        changing_fields[:bathrooms] = new_prop.bathrooms
      end

      if new_prop.parking_spaces != curr_prop.parking_spaces
        different = true
        changing_fields[:parking_spaces] = new_prop.parking_spaces
      end

      if new_prop.neighborhood != curr_prop.neighborhood
        different = true
        changing_fields[:neighborhood] = new_prop.neighborhood
      end

      different
    end

    def compare_user(curr_prop, new_prop, changing_fields, users, no_prop_users)
      different = false

      new_user = new_prop.user
      curr_user = curr_prop.user

      if new_user.nil?
        return false if curr_user.nil?

        changing_fields[:user] = new_user
        return true
      end

      # New User
      if curr_user.nil?
        user = get_user(new_user, users)

        no_prop_users.delete(user.email)
        changing_fields[:user] = user
        return true
      end

      user_changing_fields = Hash.new
      no_prop_users.delete(curr_user.email)

      if new_user.email != curr_user.email
        user_changing_fields[:email] = new_user.email
        different = true
      end

      if new_user.company != curr_user.company
        user_changing_fields[:company] = new_user.company
        different = true
      end

      if new_user.phone != curr_user.phone
        user_changing_fields[:phone] = new_user.phone
        different = true
      end

      if new_user.first_name != curr_user.first_name
        user_changing_fields[:first_name] = new_user.first_name
        different = true
      end

      if new_user.last_name != curr_user.last_name
        user_changing_fields[:last_name] = new_user.last_name
        different = true
      end

      if different
        user.update(user_changing_fields)
        users[curr_user.email] = user
      end

      # There is no need to update property relation if just some user fields have changed
      false
    end

    def get_user(new_user, users)
      user = users[new_user.email]

      if (user.nil?)
        user = new_user.save
        users[user.email] = user
      end
      user
    end

    def compare_currency(curr_prop, new_prop, changing_fields, currencies)
      new_currency = new_prop.currency
      curr_currency = curr_prop.currency

      if curr_currency.nil? || (new_currency.code != curr_currency.code)
        currency = get_currency(currencies, new_currency)
        changing_fields[:currency] = currency

        return true
      end

      false
    end

    def get_currency(currencies, new_currency)
      currency = currencies[new_currency.code]
      if currency.nil?
        currency = Currency.create(code: new_currency.code)
        currencies[new_currency.code] = currency
      end

      currency
    end

    def compare_property_type(curr_prop, new_prop, changing_fields, property_types)
      new_prop_type = new_prop.property_type
      curr_prop_type = curr_prop.property_type

      if curr_prop_type.nil? || (new_prop_type.name != curr_prop_type.name)
        prop_type = get_property_type(new_prop_type, property_types)

        changing_fields[:property_type] = prop_type
        return true
      end

      false
    end

    def get_property_type(new_prop_type, property_types)
      prop_type = property_types[new_prop_type.name]
      if prop_type.nil?
        prop_type = PropertyType.create(name: new_prop_type.name)
        property_types[new_prop_type.name] = prop_type
      end
      prop_type
    end

    def compare_features(curr_prop, new_prop, changing_fields, features)
      curr_features = curr_property_features(curr_prop)
      different = false

      new_prop.features.each do |new_feature|
        if curr_features.include?(new_feature.name)
          curr_features.delete(new_feature.name)
        else
          get_feature(features, new_feature, new_prop)

          different = true
        end
      end

      different = true unless curr_features.empty?

      if different
        changing_fields[:features] = new_prop.features
      end

      different
    end

    def get_feature(features, new_feature, new_prop)
      feature = features[new_feature.name]
      if feature.nil?
        feature = Feature.new(name: new_feature.name)
        feature.properties = []
        feature.properties.append(new_prop)
        feature.save

        features[new_feature.name] = feature
      end
      feature
    end

    def compare_images(curr_prop, new_prop, changing_fields)
      curr_images = curr_property_images(curr_prop)
      different = false

      new_prop.images.each do |new_image|
        image = curr_images[new_image.url]
        if image.nil?
          image.property = new_prop

          aux = Image.where(url: image.url).take
          Image.destroy(aux.id) unless aux.nil?

          image.save
          different = true
        else
          if new_image.order != image.order
            image.update(order: new_image.order)
            # No need to mark as different since the relation with property doesn't change
          end

          curr_images.delete(new_image.url)
        end
      end

      return different if curr_images.empty?

      different = true
      curr_images.each_value do |img|
        Image.destroy(img.id)
      end

      if different
        changing_fields[:images] = new_prop.images
      end
      different
    end
  end
end
