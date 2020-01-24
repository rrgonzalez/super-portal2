class Image < ApplicationRecord
  belongs_to :property

  validates :property, presence: true
  validates :url, :order, presence: true, uniqueness: true
end
