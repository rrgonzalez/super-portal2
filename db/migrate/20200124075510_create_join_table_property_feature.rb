class CreateJoinTablePropertyFeature < ActiveRecord::Migration[5.2]
  def change
    create_join_table :properties, :features do |t|
      # t.index [:property_id, :feature_id]
      # t.index [:feature_id, :property_id]
    end
  end
end
