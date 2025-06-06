require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "should belong to user" do
    product = products(:pancake)
    assert_equal users(:one), product.user
  end

  test "should have many product ingredients" do
    product = products(:pancake)
    assert_includes product.product_ingredients, product_ingredients(:pancake_flour)
    assert_includes product.product_ingredients, product_ingredients(:pancake_milk)
  end

  test "should require name" do
    product = Product.new(count: 1.0, user: users(:one))
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "should require count" do
    product = Product.new(name: "Test Product", user: users(:one))
    assert_not product.valid?
    assert_includes product.errors[:count], "can't be blank"
  end

  test "should require positive count" do
    product = Product.new(name: "Test Product", count: 0.0, user: users(:one))
    assert_not product.valid?
    assert_includes product.errors[:count], "must be greater than 0"
  end

  test "should calculate total cost correctly" do
    product = products(:pancake)
    
    # パンケーキの材料:
    # 小麦粉: 300円/1000g = 0.3円/g → 200g = 60円
    # 牛乳: 180円/1000ml = 0.18円/ml → 300ml = 54円
    # 合計: 60 + 54 = 114円
    expected_total_cost = (300.0 / 1000.0 * 200.0) + (180.0 / 1000.0 * 300.0)
    assert_in_delta expected_total_cost, product.total_cost, 0.01
  end

  test "should calculate cost per unit correctly" do
    product = products(:pancake)
    
    # 総原価 / 製品数 = 114円 / 10個 = 11.4円/個
    expected_cost_per_unit = product.total_cost / 10.0
    assert_in_delta expected_cost_per_unit, product.cost_per_unit, 0.01
  end

  test "should calculate legacy-style cost correctly" do
    user = create_test_user(email: "cost_test@example.com")
    unit_g = Unit.create!(name: "g", user: user)
    
    material1 = Material.create!(name: "小麦粉", price: 300.0, user: user)
    material2 = Material.create!(name: "砂糖", price: 200.0, user: user)
    
    # MaterialQuantityを作成（gの単位で）
    MaterialQuantity.create!(material: material1, unit: unit_g, count: 1000.0)  # 1000gあたり300円
    MaterialQuantity.create!(material: material2, unit: unit_g, count: 1000.0)  # 1000gあたり200円
    
    product = Product.create!(name: "テストケーキ", count: 8.0, user: user)
    
    # 小麦粉 500g = 500/1000 × 300円 = 150円
    ProductIngredient.create!(
      product: product,
      material: material1,
      unit: unit_g,
      count: 500.0
    )
    
    # 砂糖 200g = 200/1000 × 200円 = 40円
    ProductIngredient.create!(
      product: product,
      material: material2,
      unit: unit_g,
      count: 200.0
    )
    
    # 総コスト = 150 + 40 = 190円
    assert_equal 190.0, product.cost
    
    # １つあたりのコスト = 190 / 8 = 23.75円
    assert_equal 23.75, product.cost_per_unit
  end

  test "should detect invalid cost when no ingredients" do
    user = create_test_user(email: "invalid_cost_test@example.com")
    product = Product.create!(name: "空の製品", count: 4.0, user: user)
    
    assert product.invalid_cost
  end

  test "should detect invalid cost when has invalid ingredient" do
    user = create_test_user(email: "invalid_ingredient_test@example.com")
    unit_g = Unit.create!(name: "g", user: user)
    unit_ml = Unit.create!(name: "ml", user: user)
    material = Material.create!(name: "材料", price: 100.0, user: user)
    
    # unit_kgのMaterialQuantityを作らないので、unit_mlではコスト計算ができない
    product = Product.create!(name: "無効な製品", count: 2.0, user: user)
    
    ProductIngredient.create!(
      product: product,
      material: material,
      unit: unit_ml,  # この単位では材料量が設定されていない
      count: 100.0
    )
    
    assert product.invalid_cost
    assert product.has_invalid_ingredient
  end
end
