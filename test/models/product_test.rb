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
end
