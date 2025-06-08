require "application_system_test_case"

class EndToEndTest < ApplicationSystemTestCase
  test "complete user journey from signup to cost calculation" do
    # Step 1: User Registration
    visit root_path

    within "nav" do
      click_on "新規登録"
    end

    fill_in "メールアドレス", with: "baker@example.com"
    fill_in "パスワード", with: "password123"
    fill_in "パスワード（確認）", with: "password123"

    click_button "登録"

    assert_text "Welcome! You have signed up successfully."

    # Step 2: Update cost rate setting
    click_on "設定"

    fill_in "原価率（小数）", with: "0.25"
    fill_in "現在のパスワード", with: "password123"

    click_button "更新"

    assert_text "Your account has been updated successfully."

    # Step 3: Create units
    # Note: In a real scenario, units might be seeded or created via UI
    # For this test, we'll create them directly
    user = User.find_by(email: "baker@example.com")
    unit_g = Unit.create!(name: "g", user: user)
    unit_ml = Unit.create!(name: "ml", user: user)
    unit_個 = Unit.create!(name: "個", user: user)

    # Step 4: Create materials
    click_on "材料"
    click_on "材料追加"

    # Add flour
    fill_in "材料名", with: "強力粉"
    fill_in "価格 (円)", with: "300"
    fill_in "数量", with: "1000"
    select "g", from: "単位"
    click_button "新規登録"
    assert_text "Material was successfully created."

    # Add butter
    click_on "材料追加"
    fill_in "材料名", with: "バター"
    fill_in "価格 (円)", with: "400"
    fill_in "数量", with: "200"
    select "g", from: "単位"
    click_button "新規登録"
    assert_text "Material was successfully created."

    # Add eggs
    click_on "材料追加"
    fill_in "材料名", with: "卵"
    fill_in "価格 (円)", with: "250"
    fill_in "数量", with: "10"
    select "個", from: "単位"
    click_button "新規登録"
    assert_text "Material was successfully created."

    # Add milk
    click_on "材料追加"
    fill_in "材料名", with: "牛乳"
    fill_in "価格 (円)", with: "200"
    fill_in "数量", with: "1000"
    select "ml", from: "単位"
    click_button "新規登録"
    assert_text "Material was successfully created."

    # Step 5: Create a product
    click_on "製品"
    click_on "製品追加"

    fill_in "製品名", with: "クロワッサン"
    fill_in "仕込み数", with: "12"

    # Add ingredients
    within ".ingredient-row", match: :first do
      fill_in "材料名を選択・入力", with: "強力粉"
      fill_in "分量", with: "500"
      select "g", from: "単位"
    end

    click_on "材料追加", match: :first
    within all(".ingredient-row").last do
      fill_in "材料名を選択・入力", with: "バター"
      fill_in "分量", with: "150"
      select "g", from: "単位"
    end

    click_on "材料追加", match: :first
    within all(".ingredient-row").last do
      fill_in "材料名を選択・入力", with: "卵"
      fill_in "分量", with: "2"
      select "個", from: "単位"
    end

    click_on "材料追加", match: :first
    within all(".ingredient-row").last do
      fill_in "材料名を選択・入力", with: "牛乳"
      fill_in "分量", with: "200"
      select "ml", from: "単位"
    end

    click_button "新規登録"

    assert_text "Product was successfully created."

    # Step 6: Verify cost calculations
    assert_text "クロワッサン"
    assert_text "仕込み数: 12"

    # Verify that costs are calculated
    # Cost = (500g * 300円/1000g) + (150g * 400円/200g) + (2個 * 250円/10個) + (200ml * 200円/1000ml)
    #      = 150 + 300 + 50 + 40 = 540円
    assert_text "原価: ¥540.00"

    # Cost per unit = 540円 / 12個 = 45円
    assert_text "１つあたり原価: ¥45.00"

    # Selling price at 25% cost rate = 45円 / 0.25 = 180円
    assert_text "原価25%として: ¥180.00"

    # Step 7: View product details
    click_on "詳細"

    assert_text "原材料"
    assert_text "強力粉"
    assert_text "500 g"
    assert_text "¥150.00"

    assert_text "バター"
    assert_text "150 g"
    assert_text "¥300.00"

    assert_text "卵"
    assert_text "2 個"
    assert_text "¥50.00"

    assert_text "牛乳"
    assert_text "200 ml"
    assert_text "¥40.00"

    # Step 8: Navigate back and verify product in list
    click_on "← 製品一覧に戻る"

    # Should be scrolled to the product with highlight
    assert_selector "#product-#{Product.last.id}.ring-2"

    # Step 9: Search functionality
    fill_in "製品名で検索...", with: "クロワッサン"
    assert_text "クロワッサン"

    # Step 10: Logout
    click_on "ログアウト"
    assert_text "Signed out successfully."
  end

  test "cost calculation updates when material prices change" do
    # Setup user with materials and product
    user = User.create!(
      email: "updater@example.com",
      password: "password123",
      password_confirmation: "password123",
      profit_ratio: 0.3
    )

    unit = Unit.create!(name: "個", user: user)

    material = Material.create!(name: "りんご", user: user, price: 1000.0)
    material_qty = MaterialQuantity.create!(
      material: material,
      unit: unit,
      count: 10
    )

    product = Product.create!(name: "アップルパイ", count: 5, user: user)
    ProductIngredient.create!(
      product: product,
      material: material,
      unit: unit,
      count: 5
    )

    sign_in_as(user)

    # Check initial cost
    visit product_path(product)
    assert_text "¥500.00" # 5個 * (1000円/10個) = 500円
    assert_text "１つあたり原価: ¥100.00" # 500円 / 5個
    assert_text "原価30%として: ¥333.33" # 100円 / 0.3

    # Update material price
    visit materials_path
    within "#material-#{material.id}" do
      click_on "編集"
    end

    fill_in "価格 (円)", with: "1500"
    click_button "更新"

    # Check updated cost
    visit product_path(product)
    assert_text "¥750.00" # 5個 * (1500円/10個) = 750円
    assert_text "１つあたり原価: ¥150.00" # 750円 / 5個
    assert_text "原価30%として: ¥500.00" # 150円 / 0.3
  end

end
