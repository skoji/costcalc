require "test_helper"

class ProductFormTest < ActiveSupport::TestCase
  def setup
    @user = create_test_user(email: "form_test@example.com")
    @unit_g = Unit.create!(name: "g", user: @user)
    @unit_kg = Unit.create!(name: "kg", user: @user)
    @material = Material.create!(name: "小麦粉", price: 300.0, user: @user)

    # MaterialQuantityを作成してコスト計算を可能にする
    MaterialQuantity.create!(
      material: @material,
      unit: @unit_kg,
      count: 1.0
    )
  end

  test "should create new product form" do
    form = ProductForm.new
    assert_not form.persisted?
    assert_equal [], form.product_ingredients
  end

  test "should initialize with product attributes" do
    form = ProductForm.new(
      product_name: "テストケーキ",
      product_count: 8.0
    )

    assert_equal "テストケーキ", form.product_name
    assert_equal 8.0, form.product_count
  end

  test "should add product ingredient" do
    form = ProductForm.new
    ingredient_form = ProductIngredientForm.new(
      material_id: @material.id,
      unit_id: @unit_g.id,
      ingredient_count: 200.0
    )

    form.add_product_ingredient(ingredient_form)
    assert_equal 1, form.product_ingredients.count
  end

  test "should persist product with ingredients" do
    form = ProductForm.new(
      product_name: "テストケーキ",
      product_count: 8.0,
      product_ingredients_attributes: {
        "0" => {
          material_id: @material.id,
          unit_id: @unit_g.id,
          ingredient_count: 200.0
        }
      }
    )

    assert_difference "Product.count", 1 do
      assert_difference "ProductIngredient.count", 1 do
        form.persist!(@user)
      end
    end

    product = form.product
    assert_equal "テストケーキ", product.name
    assert_equal 8.0, product.count
    assert_equal @user, product.user
    assert_equal 1, product.product_ingredients.count

    ingredient = product.product_ingredients.first
    assert_equal @material, ingredient.material
    assert_equal @unit_g, ingredient.unit
    assert_equal 200.0, ingredient.count
  end

  test "should load existing product for editing" do
    product = Product.create!(
      name: "既存製品",
      count: 6.0,
      user: @user
    )

    ProductIngredient.create!(
      product: product,
      material: @material,
      unit: @unit_g,
      count: 150.0
    )

    form = ProductForm.new(id: product.id)

    assert form.persisted?
    assert_equal "既存製品", form.product_name
    assert_equal 6.0, form.product_count
    assert_equal 1, form.product_ingredients.count

    ingredient_form = form.product_ingredients.first
    assert_equal @material.id, ingredient_form.material_id
    assert_equal @unit_g.id, ingredient_form.unit_id
    assert_equal 150.0, ingredient_form.ingredient_count
  end

  test "should update existing product" do
    product = Product.create!(
      name: "既存製品",
      count: 6.0,
      user: @user
    )

    form = ProductForm.new(
      id: product.id,
      product_name: "更新製品",
      product_count: 10.0,
      product_ingredients_attributes: {
        "0" => {
          material_id: @material.id,
          unit_id: @unit_g.id,
          ingredient_count: 300.0
        }
      }
    )

    assert_no_difference "Product.count" do
      form.persist!(@user)
    end

    product.reload
    assert_equal "更新製品", product.name
    assert_equal 10.0, product.count
  end
end
