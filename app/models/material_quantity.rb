class MaterialQuantity < ApplicationRecord
  belongs_to :material
  belongs_to :unit
  
  validates :count, presence: true, numericality: { greater_than: 0 }
end
