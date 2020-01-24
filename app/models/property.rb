class Property < ApplicationRecord
  belongs_to :property_type
  belongs_to :currency
  belongs_to :user

  has_many :images
  has_and_belongs_to_many :features

  validates :property_type, :title, :description, :currency,
            :external_id, :neighborhood, presence: true
  validates :external_id, uniqueness: true
  validate :operation_present?

  def operation_present?
    unless sale? || rental?
      errors.add :base, 'Must specify at least one operation'
    end
  end
end
