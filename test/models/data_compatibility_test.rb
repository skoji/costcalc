require "test_helper"

class DataCompatibilityTest < ActiveSupport::TestCase
  # Fixtureを使用しない（このテストでは独自にデータ作成）
  self.use_transactional_tests = true
  self.fixture_sets = []
  test "existing legacy data structure compatibility" do
    # 既存DB構造のテストデータを作成
    user = User.create!(
      email: "legacy@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # 単位を作成
    unit_gram = Unit.create!(name: "g", user: user)
    unit_liter = Unit.create!(name: "L", user: user)

    # 材料を作成（既存の構造と同じ）
    material_flour = Material.create!(
      name: "小麦粉",
      price: 300.0,
      user: user
    )

    material_milk = Material.create!(
      name: "牛乳",
      price: 180.0,
      user: user
    )

    # 材料数量を作成
    MaterialQuantity.create!(
      count: 1000.0,  # 1kg = 1000g
      unit: unit_gram,
      material: material_flour
    )

    MaterialQuantity.create!(
      count: 1.0,  # 1L
      unit: unit_liter,
      material: material_milk
    )

    # 製品を作成
    product = Product.create!(
      name: "パンケーキ",
      count: 10.0,  # 10枚
      user: user
    )

    # 製品の原材料を作成
    ProductIngredient.create!(
      product: product,
      material: material_flour,
      unit: unit_gram,
      count: 200.0  # 200g
    )

    ProductIngredient.create!(
      product: product,
      material: material_milk,
      unit: unit_liter,
      count: 0.3  # 300ml = 0.3L
    )

    # 関連の確認
    assert_equal 2, user.materials.count
    assert_equal 1, user.products.count
    assert_equal 2, user.units.count

    # 材料数量の確認
    assert_equal 1, material_flour.material_quantities.count
    assert_equal 1, material_milk.material_quantities.count

    # 製品原材料の確認
    assert_equal 2, product.product_ingredients.count
    assert_equal 2, product.materials.count

    # 原価計算ロジックのテスト
    # 小麦粉: 300円/1000g = 0.3円/g → 200g = 60円
    # 牛乳: 180円/1L = 180円/L → 0.3L = 54円
    # 合計: 114円
    expected_total_cost = (300.0 / 1000.0 * 200.0) + (180.0 / 1.0 * 0.3)
    assert_in_delta expected_total_cost, product.total_cost, 0.01

    # 1枚あたりの原価
    expected_cost_per_unit = expected_total_cost / 10.0
    assert_in_delta expected_cost_per_unit, product.cost_per_unit, 0.01
  end

  test "validates required fields like legacy application" do
    user = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")

    # ユーザーなしでは材料を作成できない
    material = Material.new(name: "テスト材料", price: 100.0)
    assert_not material.valid?
    assert_includes material.errors[:user], "must exist"

    # 名前なしでは材料を作成できない
    material = Material.new(user: user, price: 100.0)
    assert_not material.valid?
    assert_includes material.errors[:name], "can't be blank"

    # 価格なしでは材料を作成できない
    material = Material.new(user: user, name: "テスト材料")
    assert_not material.valid?
    assert_includes material.errors[:price], "can't be blank"

    # 負の価格では材料を作成できない
    material = Material.new(user: user, name: "テスト材料", price: -10.0)
    assert_not material.valid?
    assert_includes material.errors[:price], "must be greater than or equal to 0"
  end

  test "cascade delete behavior matches legacy" do
    user = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")
    unit = Unit.create!(name: "g", user: user)
    material = Material.create!(name: "材料", price: 100.0, user: user)
    product = Product.create!(name: "製品", count: 1.0, user: user)

    material_quantity = MaterialQuantity.create!(
      count: 100.0,
      unit: unit,
      material: material
    )

    product_ingredient = ProductIngredient.create!(
      product: product,
      material: material,
      unit: unit,
      count: 50.0
    )

    # 材料を削除すると関連データも削除される
    material.destroy
    assert_not MaterialQuantity.exists?(material_quantity.id)
    assert_not ProductIngredient.exists?(product_ingredient.id)

    # ユーザーを削除すると全関連データが削除される
    unit_id = unit.id
    product_id = product.id
    user.destroy

    assert_not Unit.exists?(unit_id)
    assert_not Product.exists?(product_id)
  end
end
