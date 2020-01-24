class AddNeighborhoodToProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :properties, :neighborhood, :string
    change_column :properties, :neighborhood, :string, null: false
  end
end
