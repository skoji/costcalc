class Unit < ApplicationRecord
  belongs_to :user
  has_many :material_quantities, dependent: :destroy
  has_many :product_ingredients, dependent: :destroy
  
  validates :name, presence: true
end
