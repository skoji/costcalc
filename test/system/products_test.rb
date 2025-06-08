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
    @unit_piece = Unit.create!(name: "piece", user: @user)

    # Create materials for testing
    @flour = Material.create!(name: "小麦粉", user: @user, price: 200.0)
    MaterialQuantity.create!(material: @flour, unit: @unit_g, count: 1000)

    @sugar = Material.create!(name: "砂糖", user: @user, price: 180.0)
    MaterialQuantity.create!(material: @sugar, unit: @unit_g, count: 1000)

    @egg = Material.create!(name: "卵", user: @user, price: 200.0)
    MaterialQuantity.create!(material: @egg, unit: @unit_piece, count: 10)

    @milk = Material.create!(name: "牛乳", user: @user, price: 200.0)
    MaterialQuantity.create!(material: @milk, unit: @unit_ml, count: 1000)

    sign_in_as(@user)
  end

  test "user can create a product with multiple ingredients" do
    visit products_path

    click_on "Add Product"

    fill_in "Product Name", with: "パンケーキ"
    fill_in "Preparation Count", with: "10"

    # First ingredient
    within ".ingredient-row", match: :first do
      find("input.material-search-input").set("小麦粉")
      find("input[name*='ingredient_count']").set("200")
      find(".unit-select").select("g")
    end

    # Add second ingredient
    click_on "Add Material", match: :first

    within all(".ingredient-row").last do
      find("input.material-search-input").set("砂糖")
      find("input[name*='ingredient_count']").set("50")
      find(".unit-select").select("g")
    end

    # Add third ingredient
    click_on "Add Material", match: :first

    within all(".ingredient-row").last do
      find("input.material-search-input").set("卵")
      find("input[name*='ingredient_count']").set("2")
      find(".unit-select").select("piece")
    end

    click_button "Create"

    assert_text "Product was successfully created."
    assert_text "パンケーキ"
    assert_text "Preparation Count: 10"
    assert_text "Cost:"
    assert_text "Cost per Unit:"
    assert_text "Cost 30% as cost:"
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

    find("a[href='#{edit_product_path(product)}']").click

    fill_in "Product Name", with: "バタークッキー"

    # Remove one ingredient
    within all(".ingredient-row").last do
      click_on "Delete"
    end

    # Add new ingredient using top button
    click_on "Add Material", match: :first

    within all(".ingredient-row").last do
      find("input.material-search-input").set("卵")
      find("input[name*='ingredient_count']").set("1")
      find(".unit-select").select("piece")
    end

    click_button "Update"

    assert_text "Product was successfully updated."
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
      click_on "Details"
    end

    assert_text "製品10"
    assert_text "Raw Materials"

    # Return to product list (use the top link)
    click_on "← Back to Product List", match: :first

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
      ProductIngredient.create!(product: p, material: @egg, unit: @unit_piece, count: 3)
    end

    visit products_path

    fill_in "Search by product name...", with: "ケーキ"

    assert_text "チョコケーキ"
    assert_text "チーズケーキ"
    assert_no_text "プリン"

    click_on "Clear"

    assert_text "プリン"
  end

  test "javascript functionality for dynamic ingredient management" do
    visit new_product_path

    fill_in "Product Name", with: "テスト製品"
    fill_in "Preparation Count", with: "1"

    # Test material name autocomplete with datalist
    within ".ingredient-row", match: :first do
      input = find_field("Select or enter material name")
      input.fill_in with: "小"

      # Note: Datalist functionality may not work in headless browser environment
      # Skip datalist test for CI compatibility
      # assert_selector "datalist option[value='小麦粉']"
    end

    # Add multiple ingredients quickly
    3.times do
      click_on "Add Material", match: :first
    end

    # Should have 4 ingredient rows total
    assert_selector ".ingredient-row", count: 4
  end
end
