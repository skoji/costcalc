class ProductIngredient < ApplicationRecord
  belongs_to :product
  belongs_to :material
  belongs_to :unit
  
  validates :count, presence: true, numericality: { greater_than: 0 }
  
  def cost
    material_price = material.price
    material_quantity = material.material_quantities.find do |q|
      q.unit.id == unit.id
    end
    return nil if (!material_quantity || count.nil? || material_price.nil?)
    (count / material_quantity.count) * material_price
  end

  def invalid_cost
    cost.nil? || cost <= 0
  end
end
