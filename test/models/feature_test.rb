require 'test_helper'

class FeatureTest < ActiveSupport::TestCase
  test 'create' do
    feature = Feature.create name: 'Roof Garden'
    assert feature.save

    feature2 = Feature.create name: 'Roof Garden'
    refute feature2.save
  end

  test 'required fields' do
    feature = Feature.create
    refute feature.valid?

    feature.name = 'Patio'
    assert feature.valid?
  end

  test 'relations' do
    feature = Feature.new
    assert_kind_of Array, properties
  end
end
