require "test_helper"

class ProductIngredientFormTest < ActiveSupport::TestCase
  def setup
    @user = create_test_user(email: "ingredient_test@example.com")
    @unit_g = Unit.create!(name: "g", user: @user)
    @unit_kg = Unit.create!(name: "kg", user: @user)
    @material = Material.create!(name: "砂糖", price: 200.0, user: @user)

    # MaterialQuantityを作成してコスト計算を可能にする
    @material_quantity = MaterialQuantity.create!(
      material: @material,
      unit: @unit_kg,
      count: 1.0
    )

    @product = Product.create!(
      name: "テスト製品",
      count: 4.0,
      user: @user
    )
  end

  test "should create new ingredient form" do
    form = ProductIngredientForm.new(
      material_id: @material.id,
      unit_id: @unit_g.id,
      ingredient_count: 100.0
    )

    assert_equal @material.id, form.material_id
    assert_equal @unit_g.id, form.unit_id
    assert_equal 100.0, form.ingredient_count
  end

  test "should initialize from existing product ingredient" do
    ingredient = ProductIngredient.create!(
      product: @product,
      material: @material,
      unit: @unit_g,
      count: 150.0
    )

    form = ProductIngredientForm.new(ingredient)

    assert_equal ingredient.id, form.id
    assert_equal @material.id, form.material_id
    assert_equal @unit_g.id, form.unit_id
    assert_equal 150.0, form.ingredient_count
    assert_equal @material.name, form.material_name
    assert_equal @unit_g.name, form.unit_name
  end

  test "should persist new ingredient" do
    form = ProductIngredientForm.new(
      material_id: @material.id,
      unit_id: @unit_g.id,
      ingredient_count: 200.0
    )

    assert_difference "ProductIngredient.count", 1 do
      form.persist!(@product)
    end

    ingredient = ProductIngredient.last
    assert_equal @product, ingredient.product
    assert_equal @material, ingredient.material
    assert_equal @unit_g, ingredient.unit
    assert_equal 200.0, ingredient.count
  end

  test "should not persist ingredient with invalid material_id" do
    form = ProductIngredientForm.new(
      material_id: -1,
      unit_id: @unit_g.id,
      ingredient_count: 200.0
    )

    assert_no_difference "ProductIngredient.count" do
      form.persist!(@product)
    end
  end

  test "should not persist ingredient with blank material_id" do
    form = ProductIngredientForm.new(
      material_id: nil,
      unit_id: @unit_g.id,
      ingredient_count: 200.0
    )

    assert_no_difference "ProductIngredient.count" do
      form.persist!(@product)
    end
  end

  test "should delete ingredient when delete flag is set" do
    ingredient = ProductIngredient.create!(
      product: @product,
      material: @material,
      unit: @unit_g,
      count: 150.0
    )

    form = ProductIngredientForm.new(ingredient)
    form.delete = "1"

    # Note: Deletion is now handled at ProductForm level, not here
    # ProductIngredientForm.persist! now skips when delete = "1"
    assert_no_difference "ProductIngredient.count" do
      form.persist!(@product)
    end
  end

  test "should not delete new ingredient when delete flag is set" do
    form = ProductIngredientForm.new(
      material_id: @material.id,
      unit_id: @unit_g.id,
      ingredient_count: 200.0,
      delete: "1"
    )

    # Should not create ingredient when delete flag is set
    assert_no_difference "ProductIngredient.count" do
      form.persist!(@product)
    end
  end
end
