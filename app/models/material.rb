class Material < ApplicationRecord
  belongs_to :user
  has_many :material_quantities, dependent: :destroy
  has_many :product_ingredients, dependent: :destroy
  has_many :products, through: :product_ingredients

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def unit_price(unit)
    material_quantity = material_quantities.find_by(unit: unit)
    return 0 unless material_quantity&.count&.positive?

    price / material_quantity.count
  end
end
