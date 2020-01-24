class CreateFeatures < ActiveRecord::Migration[5.2]
  def change
    create_table :features do |t|
      t.string :name, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
