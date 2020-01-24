class RenameImagesNameToUrl < ActiveRecord::Migration[5.2]
  def change
    rename_column :images, :name, :url
  end
end
