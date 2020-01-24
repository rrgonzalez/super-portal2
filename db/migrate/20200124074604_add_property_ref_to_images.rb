class AddPropertyRefToImages < ActiveRecord::Migration[5.2]
  def change
    add_reference :images, :property, foreign_key: true
  end
end
