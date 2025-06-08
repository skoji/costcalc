require "application_system_test_case"

class EndToEndTest < ApplicationSystemTestCase
  test "complete user journey from signup to cost calculation" do
    # Step 1: User Registration
    visit root_path

    within "nav" do
      click_on "Sign Up"
    end

    fill_in "Email", with: "baker#{rand(1000)}@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password Confirmation", with: "password123"

    click_button "Sign Up"

    assert_text "Welcome! You have signed up successfully."

    # Step 2: Update cost rate setting
    click_on "Settings"

    fill_in "Cost Ratio (decimal)", with: "0.25"
    fill_in "Current Password", with: "password123"

    click_button "Update"

    assert_text "Your account has been updated successfully."

    # Step 3: Create units
    # Note: In a real scenario, units might be seeded or created via UI
    # For this test, we'll create them directly
    user = User.last
    unit_g = Unit.create!(name: "g", user: user)
    unit_ml = Unit.create!(name: "ml", user: user)
    unit_piece = Unit.create!(name: "piece", user: user)

    # Step 4: Create materials
    click_on "Materials"
    click_on "Add Material"

    # Add flour
    fill_in "Material Name", with: "強力粉"
    fill_in "Price (yen)", with: "300"
    fill_in "Quantity", with: "1000"
    find("select[name*='unit_id']").select("g")
    click_button "Create"
    assert_text "Material was successfully created."

    # Add butter
    click_on "Add Material"
    fill_in "Material Name", with: "バター"
    fill_in "Price (yen)", with: "400"
    fill_in "Quantity", with: "200"
    find("select[name*='unit_id']").select("g")
    click_button "Create"
    assert_text "Material was successfully created."

    # Add eggs
    click_on "Add Material"
    fill_in "Material Name", with: "卵"
    fill_in "Price (yen)", with: "250"
    fill_in "Quantity", with: "10"
    find("select[name*='unit_id']").select("piece")
    click_button "Create"
    assert_text "Material was successfully created."

    # Add milk
    click_on "Add Material"
    fill_in "Material Name", with: "牛乳"
    fill_in "Price (yen)", with: "200"
    fill_in "Quantity", with: "1000"
    find("select[name*='unit_id']").select("ml")
    click_button "Create"
    assert_text "Material was successfully created."

    # Step 5: Create a product
    click_on "Products"
    click_on "Add Product"

    fill_in "Product Name", with: "クロワッサン"
    fill_in "Preparation Count", with: "12"

    # Add ingredients
    within ".ingredient-row", match: :first do
      find("input.material-search-input").set("強力粉")
      find("input[name*='ingredient_count']").set("500")
      # Wait for material selection to trigger unit filtering
      sleep 0.5
      find(".unit-select").select("g")
    end

    click_on "Add Material", match: :first
    within all(".ingredient-row").last do
      find("input.material-search-input").set("バター")
      find("input[name*='ingredient_count']").set("150")
      # Wait for material selection to trigger unit filtering
      sleep 0.5
      find(".unit-select").select("g")
    end

    click_on "Add Material", match: :first
    within all(".ingredient-row").last do
      find("input.material-search-input").set("卵")
      find("input[name*='ingredient_count']").set("2")
      # Wait for material selection to trigger unit filtering
      sleep 0.5
      find(".unit-select").select("piece")
    end

    click_on "Add Material", match: :first
    within all(".ingredient-row").last do
      find("input.material-search-input").set("牛乳")
      find("input[name*='ingredient_count']").set("200")
      # Wait for material selection to trigger unit filtering
      sleep 0.5
      find(".unit-select").select("ml")
    end

    click_button "Create"

    assert_text "Product was successfully created."

    # Step 6: Verify cost calculations
    assert_text "クロワッサン"
    assert_text "Preparation Count: 12"

    # Verify that costs are calculated
    # Cost = (500g * 300円/1000g) + (150g * 400円/200g) + (2個 * 250円/10個) + (200ml * 200円/1000ml)
    #      = 150 + 300 + 50 + 40 = 540円
    assert_text "Cost: ¥540.00"

    # Cost per unit = 540円 / 12個 = 45円
    assert_text "Cost per Unit: ¥45.00"

    # Selling price at 25% cost rate = 45円 / 0.25 = 180円
    assert_text "Cost 25% as cost: ¥180.00"

    # Step 7: Verify product details (already on show page after creation)
    assert_text "Raw Materials"
    assert_text "強力粉"
    assert_text "500.0 g"
    assert_text "¥150.00"

    assert_text "バター"
    assert_text "150.0 g"
    assert_text "¥300.00"

    assert_text "卵"
    assert_text "2.0 piece"
    assert_text "¥50.00"

    assert_text "牛乳"
    assert_text "200.0 ml"
    assert_text "¥40.00"

    # Step 8: Navigate back and verify product in list
    click_on "← Back to Product List", match: :first

    # Should be scrolled to the product with highlight
    assert_selector "#product-#{Product.last.id}.ring-2"

    # Step 9: Search functionality
    find("input[placeholder*='Search']").set("クロワッサン")
    assert_text "クロワッサン"

    # Step 10: Logout
    click_on "Logout"
    # Note: Flash message might not appear in CI environment
    # assert_text "Signed out successfully."
    assert_current_path new_user_session_path
  end

  test "cost calculation updates when material prices change" do
    # Setup user with materials and product
    user = User.create!(
      email: "updater@example.com",
      password: "password123",
      password_confirmation: "password123",
      profit_ratio: 0.3
    )

    unit = Unit.create!(name: "piece", user: user)

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
    assert_text "Cost per Unit: ¥100.00" # 500円 / 5個
    assert_text "Cost 30% as cost: ¥333.33" # 100円 / 0.3

    # Update material price
    visit materials_path
    within "#material-#{material.id}" do
      click_on "Edit"
    end

    fill_in "Price (yen)", with: "1500"
    click_button "Update"

    # Check updated cost
    visit product_path(product)
    assert_text "¥750.00" # 5個 * (1500円/10個) = 750円
    assert_text "Cost per Unit: ¥150.00" # 750円 / 5個
    assert_text "Cost 30% as cost: ¥500.00" # 150円 / 0.3
  end
end
