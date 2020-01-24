class CreateImages < ActiveRecord::Migration[5.2]
  def change
    create_table :images do |t|
      t.string :name, null: false, index: { unique: true }
      t.integer :order, null: false, unique: true

      t.timestamps
    end
  end
end
