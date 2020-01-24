class Image < ApplicationRecord
  validates :name, :order, presence: true, uniqueness: true
end
