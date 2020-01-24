class AddExternalIdToProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :properties, :external_id, :string
    change_column :properties, :external_id, :string, null: false, index: {unique: true}
  end
end
