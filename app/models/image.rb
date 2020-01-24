class Image < ApplicationRecord
  validates :url, :order, presence: true, uniqueness: true
end
