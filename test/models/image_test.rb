class ImageTest < ActiveSupport::TestCase
  test 'create' do
    img = Image.create url: 'http://images.com/image1', order: 54,
                       property: properties(:simpson_house)
    assert img.save

    img2 = Image.create url: 'http://images.com/image1', order: 54
    refute img2.save

    img2.url = 'http://images.com/image2'
    refute img2.save

    img2.property = properties(:simpson_house)
    assert img2.save
  end

  test 'required fields' do
    img = Image.create
    refute img.valid?

    img.url = 'http://images.com/image1'
    refute img.valid?

    img.order = 55
    refute img.valid?

    img.url = 'http://images.com/image1'
    img.property = properties(:simpson_house)
    assert img.valid?
  end
end
