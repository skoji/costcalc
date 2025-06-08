require "application_system_test_case"

class ProductsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "products@example.com",
      password: "password123",
      password_confirmation: "password123",
      profit_ratio: 0.3
    )

    @unit_g = Unit.create!(name: "g", user: @user)
    @unit_ml = Unit.create!(name: "ml", user: @user)
    @unit_個 = Unit.create!(name: "個", user: @user)

    # Create materials for testing
    @flour = Material.create!(name: "小麦粉", user: @user, price: 200.0)
    MaterialQuantity.create!(material: @flour, unit: @unit_g, count: 1000)

    @sugar = Material.create!(name: "砂糖", user: @user, price: 180.0)
    MaterialQuantity.create!(material: @sugar, unit: @unit_g, count: 1000)

    @egg = Material.create!(name: "卵", user: @user, price: 200.0)
    MaterialQuantity.create!(material: @egg, unit: @unit_個, count: 10)

    @milk = Material.create!(name: "牛乳", user: @user, price: 200.0)
    MaterialQuantity.create!(material: @milk, unit: @unit_ml, count: 1000)

    sign_in_as(@user)
  end

  test "user can create a product with multiple ingredients" do
    visit products_path

    click_on "製品追加"

    fill_in "製品名", with: "パンケーキ"
    fill_in "仕込み数", with: "10"

    # First ingredient
    within ".ingredient-row", match: :first do
      fill_in "材料名を選択・入力", with: "小麦粉"
      fill_in "分量", with: "200"
      select "g", from: "単位を選択"
    end

    # Add second ingredient
    click_on "材料追加", match: :first

    within all(".ingredient-row").last do
      fill_in "材料名を選択・入力", with: "砂糖"
      fill_in "分量", with: "50"
      select "g", from: "単位を選択"
    end

    # Add third ingredient
    click_on "材料追加", match: :first

    within all(".ingredient-row").last do
      fill_in "材料名を選択・入力", with: "卵"
      fill_in "分量", with: "2"
      select "個", from: "単位を選択"
    end

    click_button "新規登録"

    assert_text "製品が作成されました。"
    assert_text "パンケーキ"
    assert_text "仕込み数: 10"
    assert_text "原価:"
    assert_text "１つあたり原価:"
    assert_text "原価30%として:"
  end

  test "user can edit a product and add/remove ingredients" do
    product = Product.create!(name: "クッキー", count: 50, user: @user)
    ProductIngredient.create!(
      product: product,
      material: @flour,
      unit: @unit_g,
      count: 300
    )
    ProductIngredient.create!(
      product: product,
      material: @sugar,
      unit: @unit_g,
      count: 100
    )

    visit product_path(product)

    click_on "編集"

    fill_in "製品名", with: "バタークッキー"

    # Remove one ingredient
    within all(".ingredient-row").last do
      click_on "削除"
    end

    # Add new ingredient using top button
    click_on "材料追加", match: :first

    within all(".ingredient-row").last do
      fill_in "材料名を選択・入力", with: "卵"
      fill_in "分量", with: "1"
      select "個", from: "単位を選択"
    end

    click_button "更新"

    assert_text "製品が更新されました。"
    assert_text "バタークッキー"
    assert_text "卵"
  end

  test "user can navigate product list and return to same position" do
    # Create multiple products to enable scrolling
    20.times do |i|
      Product.create!(
        name: "製品#{i + 1}",
        count: 10,
        user: @user
      ).tap do |product|
        ProductIngredient.create!(
          product: product,
          material: @flour,
          unit: @unit_g,
          count: 100
        )
      end
    end

    visit products_path

    # Find a product in the middle of the list
    target_product = Product.find_by(name: "製品10")

    # Click on product detail
    within "#product-#{target_product.id}" do
      click_on "詳細"
    end

    assert_text "製品10"
    assert_text "原材料"

    # Return to product list (use the top link)
    click_on "← 製品一覧に戻る", match: :first

    # Verify we're scrolled to the correct position
    # The product should be highlighted temporarily
    assert_selector "#product-#{target_product.id}.ring-2"
  end

  test "user can search products" do
    chocolate_material = Material.create!(name: "チョコ", user: @user, price: 500.0)
    MaterialQuantity.create!(material: chocolate_material, unit: @unit_g, count: 100)

    Product.create!(name: "チョコケーキ", count: 1, user: @user).tap do |p|
      ProductIngredient.create!(product: p, material: chocolate_material, unit: @unit_g, count: 100)
    end

    cheese_material = Material.create!(name: "チーズ", user: @user, price: 400.0)
    MaterialQuantity.create!(material: cheese_material, unit: @unit_g, count: 100)

    Product.create!(name: "チーズケーキ", count: 1, user: @user).tap do |p|
      ProductIngredient.create!(product: p, material: cheese_material, unit: @unit_g, count: 100)
    end

    Product.create!(name: "プリン", count: 10, user: @user).tap do |p|
      ProductIngredient.create!(product: p, material: @egg, unit: @unit_個, count: 3)
    end

    visit products_path

    fill_in "製品名で検索...", with: "ケーキ"

    assert_text "チョコケーキ"
    assert_text "チーズケーキ"
    assert_no_text "プリン"

    click_on "クリア"

    assert_text "プリン"
  end

  test "javascript functionality for dynamic ingredient management" do
    visit new_product_path

    fill_in "製品名", with: "テスト製品"
    fill_in "仕込み数", with: "1"

    # Test material name autocomplete with datalist
    within ".ingredient-row", match: :first do
      input = find_field("材料名を選択・入力")
      input.fill_in with: "小"

      # Datalist should show filtered options
      assert_selector "datalist option[value='小麦粉']"
    end

    # Add multiple ingredients quickly
    3.times do
      click_on "材料追加", match: :first
    end

    # Should have 4 ingredient rows total
    assert_selector ".ingredient-row", count: 4
  end

end
