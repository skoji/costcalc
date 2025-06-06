class Product < ApplicationRecord
  belongs_to :user
  has_many :product_ingredients, dependent: :destroy
  has_many :materials, through: :product_ingredients

  validates :name, presence: true
  validates :count, presence: true, numericality: { greater_than: 0 }

  def cost
    product_ingredients.inject(0) do |sum, ingredient|
      ingredient_cost = ingredient.cost
      sum = sum + ingredient_cost if ingredient_cost
      sum
    end
  end

  def cost_per_unit
    cost && count ? cost / count : 0
  end

  def invalid_cost
    !count || !cost || has_invalid_ingredient || cost == 0
  end

  def has_invalid_ingredient
    product_ingredients.inject(false) do |result, ingredient|
      ingredient.invalid_cost || result
    end
  end

  # Rails 8版の互換性のため既存メソッドも残す
  def total_cost
    cost
  end
end
