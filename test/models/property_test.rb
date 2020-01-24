require 'test_helper'

class PropertyTest < ActiveSupport::TestCase
  test 'create' do
    property = Property.new
    property.title = 'Cool House'
    property.description = 'Super description of cool house'
    property.property_type = property_types(:house)
    property.sale = true
    property.currency = currencies(:usd)
    property.user = users(:bart)
    property.external_id = '384s'
    property.neighborhood = 'Roma Norte'
    assert property.save

    property2 = Property.new
    property2.title = 'Another Cool House'
    property2.description = 'Super description of cool house'
    property2.property_type = property_types(:house)
    property2.sale = true
    property2.currency = currencies(:usd)
    property2.user = users(:bart)
    property2.external_id = '384s'
    property2.neighborhood = 'Vertiz Narvarte'
    refute property2.save

    property2.external_id = '235r'
    assert property2.save
  end

  test 'required fields' do
    property = Property.new
    refute property.valid?

    property.title = 'Cool House'
    refute property.valid?

    property.description = 'Super description of cool house'
    refute property.valid?

    property.property_type = property_types(:house)
    refute property.valid?

    property.currency = currencies(:mxn)
    refute property.valid?

    property.user = users(:bart)
    refute property.valid?

    property.rental = true
    property.external_id = '31203r'
    refute property.valid?

    property.neighborhood = 'Condesa'
    assert property.valid?
  end

  test 'operation_present?' do
    house = properties(:simpson_house)
    house.sale = false
    house.rental = false

    refute house.valid?
    house.sale = true
    assert house.valid?

    house.sale = false
    house.rental = true
    assert house.valid?
  end
end
