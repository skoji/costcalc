require "test_helper"

class LegacyDataMigrationTest < ActiveSupport::TestCase
  # Fixtureを使用しない（このテストでは独自にデータ作成）
  self.use_transactional_tests = true
  self.fixture_sets = []
  test "can import legacy-style fixture data" do
    # 既存アプリケーションのfixtureと同等のデータ構造をテスト
    
    # ユーザー作成（Deviseスタイル）
    user1 = User.create!(
      email: "legacy_user1@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    
    user2 = User.create!(
      email: "legacy_user2@example.com", 
      password: "password123",
      password_confirmation: "password123"
    )

    # 単位作成
    unit1 = Unit.create!(name: "g", user: user1)
    unit2 = Unit.create!(name: "ml", user: user2)

    # 材料作成
    material1 = Material.create!(
      name: "小麦粉",
      price: 200.0,
      user: user1
    )
    
    material2 = Material.create!(
      name: "牛乳",
      price: 180.0,
      user: user2
    )

    # 材料数量作成（legacy fixtureのスタイル）
    mq1 = MaterialQuantity.create!(
      count: 1000.0,  # 1kg = 1000g
      unit: unit1,
      material: material1
    )
    
    mq2 = MaterialQuantity.create!(
      count: 1000.0,  # 1L = 1000ml
      unit: unit2,
      material: material2
    )

    # 製品作成
    product1 = Product.create!(
      name: "パンケーキ",
      count: 10.0,
      user: user1
    )
    
    product2 = Product.create!(
      name: "カスタードプリン",
      count: 5.0,
      user: user2
    )

    # 製品原材料作成
    pi1 = ProductIngredient.create!(
      product: product1,
      material: material1,
      unit: unit1,
      count: 200.0  # 200g
    )
    
    pi2 = ProductIngredient.create!(
      product: product2,
      material: material2,
      unit: unit2,
      count: 300.0  # 300ml
    )

    # データ整合性の確認（fixtureで作成されたデータも含むため、created_userのみをカウント）
    created_users = [user1, user2]
    assert_equal 2, created_users.count
    assert_equal 2, created_users.sum { |u| u.units.count }
    assert_equal 2, created_users.sum { |u| u.materials.count }
    assert_equal 2, MaterialQuantity.where(material: [material1, material2]).count
    assert_equal 2, created_users.sum { |u| u.products.count }
    assert_equal 2, ProductIngredient.where(product: [product1, product2]).count

    # 関連の確認
    assert_equal user1, material1.user
    assert_equal user1, unit1.user
    assert_equal user1, product1.user
    
    assert_equal material1, mq1.material
    assert_equal unit1, mq1.unit
    
    assert_equal product1, pi1.product
    assert_equal material1, pi1.material
    assert_equal unit1, pi1.unit

    # 原価計算の確認（legacy互換）
    # 小麦粉: 200円/1000g = 0.2円/g → 200g = 40円
    expected_cost_per_unit = 200.0 / 1000.0 * 200.0 / 10.0  # 4円/枚
    assert_in_delta expected_cost_per_unit, product1.cost_per_unit, 0.01
  end

  test "handles edge cases like legacy application" do
    user = User.create!(email: "edge_test@example.com", password: "password123", password_confirmation: "password123")
    unit = Unit.create!(name: "g", user: user)
    
    # ゼロ価格の材料
    material_free = Material.create!(name: "無料材料", price: 0.0, user: user)
    MaterialQuantity.create!(count: 100.0, unit: unit, material: material_free)
    
    product = Product.create!(name: "テスト製品", count: 1.0, user: user)
    ProductIngredient.create!(
      product: product,
      material: material_free,
      unit: unit,
      count: 50.0
    )
    
    # ゼロ価格でも正常に動作することを確認
    assert_equal 0.0, product.total_cost
    assert_equal 0.0, product.cost_per_unit
  end

  test "supports float precision like legacy database" do
    user = User.create!(email: "precision_test@example.com", password: "password123", password_confirmation: "password123")
    unit = Unit.create!(name: "g", user: user)
    
    # 小数点以下の価格をテスト
    material = Material.create!(
      name: "高級材料",
      price: 123.456789,  # 6桁精度
      user: user
    )
    
    MaterialQuantity.create!(
      count: 333.333333,  # 6桁精度
      unit: unit,
      material: material
    )
    
    product = Product.create!(
      name: "精密製品",
      count: 7.777777,  # 6桁精度
      user: user
    )
    
    ProductIngredient.create!(
      product: product,
      material: material,
      unit: unit,
      count: 11.111111  # 6桁精度
    )

    # 精度を保持した計算ができることを確認
    unit_price = material.unit_price(unit)
    expected_unit_price = 123.456789 / 333.333333
    assert_in_delta expected_unit_price, unit_price, 0.000001

    total_cost = product.total_cost
    expected_total_cost = unit_price * 11.111111
    assert_in_delta expected_total_cost, total_cost, 0.000001
  end

  test "preserves legacy user isolation" do
    # マルチテナント機能のテスト
    user1 = User.create!(email: "isolation_user1@example.com", password: "password123", password_confirmation: "password123")
    user2 = User.create!(email: "isolation_user2@example.com", password: "password123", password_confirmation: "password123")
    
    # 同じ名前の材料を異なるユーザーで作成
    material1 = Material.create!(name: "共通材料", price: 100.0, user: user1)
    material2 = Material.create!(name: "共通材料", price: 200.0, user: user2)
    
    # ユーザーごとに分離されていることを確認
    assert_equal 1, user1.materials.count
    assert_equal 1, user2.materials.count
    assert_equal [material1], user1.materials.to_a
    assert_equal [material2], user2.materials.to_a
    
    # 価格も独立していることを確認
    assert_equal 100.0, user1.materials.first.price
    assert_equal 200.0, user2.materials.first.price
  end
end