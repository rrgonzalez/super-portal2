class RemoveConstraintPropertyUser < ActiveRecord::Migration[5.2]
  def change
    remove_reference :properties, :user
    add_reference :properties, :user, foreign_key: true, null: true
  end
end
