require "test_helper"

class ProductIngredientTest < ActiveSupport::TestCase
  def setup
    @user = create_test_user(email: "product_ingredient_test@example.com")
    @unit_g = Unit.create!(name: "g", user: @user)
    @unit_kg = Unit.create!(name: "kg", user: @user)
    @material = Material.create!(name: "小麦粉", price: 300.0, user: @user)

    @product = Product.create!(
      name: "テストパン",
      count: 4.0,
      user: @user
    )

    @material_quantity = MaterialQuantity.create!(
      material: @material,
      unit: @unit_kg,
      count: 1.0
    )
  end

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

  test "should calculate cost correctly" do
    # 500g使用、1000gあたり300円なので、500/1000 * 300 = 150円
    # gの単位でMaterialQuantityを作成
    @material_quantity.update!(unit: @unit_g, count: 1000.0)

    ingredient = ProductIngredient.create!(
      product: @product,
      material: @material,
      unit: @unit_g,
      count: 500.0
    )

    expected_cost = (500.0 / 1000.0) * 300.0  # 150.0
    assert_equal expected_cost, ingredient.cost
  end

  test "should return nil cost when material quantity not found" do
    # mlの単位で材料量が設定されていない場合
    unit_ml = Unit.create!(name: "ml", user: @user)

    ingredient = ProductIngredient.create!(
      product: @product,
      material: @material,
      unit: unit_ml,
      count: 100.0
    )

    assert_nil ingredient.cost
  end

  test "should return nil cost when count is nil" do
    ingredient = ProductIngredient.new(
      product: @product,
      material: @material,
      unit: @unit_g,
      count: nil
    )

    assert_nil ingredient.cost
  end

  test "should detect invalid cost" do
    # コストが計算できない場合
    unit_ml = Unit.create!(name: "ml", user: @user)

    ingredient = ProductIngredient.create!(
      product: @product,
      material: @material,
      unit: unit_ml,
      count: 100.0
    )

    assert ingredient.invalid_cost
  end

  test "should detect valid cost" do
    # gの単位でMaterialQuantityを作成
    @material_quantity.update!(unit: @unit_g, count: 1000.0)

    ingredient = ProductIngredient.create!(
      product: @product,
      material: @material,
      unit: @unit_g,
      count: 500.0
    )

    assert_not ingredient.invalid_cost
  end
end
