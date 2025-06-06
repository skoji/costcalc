require "test_helper"

class ProductIngredientTest < ActiveSupport::TestCase
  test "should belong to product, material and unit" do
    pi = product_ingredients(:pancake_flour)
    assert_equal products(:pancake), pi.product
    assert_equal materials(:flour), pi.material
    assert_equal units(:gram), pi.unit
  end

  test "should require count" do
    pi = ProductIngredient.new(
      product: products(:pancake),
      material: materials(:flour),
      unit: units(:gram)
    )
    assert_not pi.valid?
    assert_includes pi.errors[:count], "can't be blank"
  end

  test "should require positive count" do
    pi = ProductIngredient.new(
      count: 0.0,
      product: products(:pancake),
      material: materials(:flour),
      unit: units(:gram)
    )
    assert_not pi.valid?
    assert_includes pi.errors[:count], "must be greater than 0"
  end
end
