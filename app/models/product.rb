class Product < ApplicationRecord
  belongs_to :user
  has_many :product_ingredients, dependent: :destroy
  has_many :materials, through: :product_ingredients
  
  validates :name, presence: true
  validates :count, presence: true, numericality: { greater_than: 0 }
  
  def total_cost
    product_ingredients.sum do |ingredient|
      material = ingredient.material
      unit_price = material.unit_price(ingredient.unit)
      unit_price * ingredient.count
    end
  end
  
  def cost_per_unit
    return 0 unless count&.positive?
    total_cost / count
  end
end
