require "application_system_test_case"

class MaterialsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "materials@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @unit_kg = Unit.create!(name: "kg", user: @user)
    @unit_g = Unit.create!(name: "g", user: @user)

    sign_in_as(@user)
  end

  test "user can create a material with multiple units" do
    visit materials_path

    click_on "材料追加"

    fill_in "材料名", with: "小麦粉"
    fill_in "価格 (円)", with: "200"

    # Set the unit information
    fill_in "数量", with: "1000"
    find("select[name*='unit_id']").select("g")

    click_button "新規登録"

    assert_text "Material was successfully created."
    assert_text "小麦粉"
    assert_text "¥200.0"
  end

  test "user can edit a material" do
    material = Material.create!(name: "砂糖", user: @user, price: 150.0)
    MaterialQuantity.create!(
      material: material,
      unit: @unit_kg,
      count: 1
    )

    visit materials_path

    within "#material-#{material.id}" do
      click_on "編集"
    end

    fill_in "材料名", with: "上白糖"
    fill_in "価格 (円)", with: "180"

    click_button "更新"

    assert_text "Material was successfully updated."
    assert_text "上白糖"
    assert_text "¥180.0"
  end

  test "user can delete a material" do
    material = Material.create!(name: "塩", user: @user, price: 50.0)
    MaterialQuantity.create!(
      material: material,
      unit: @unit_g,
      count: 100
    )

    visit edit_material_path(material)

    page.accept_confirm do
      click_link "削除"
    end

    assert_text "Material was successfully destroyed."
    assert_no_text "塩"
  end

  test "user can search materials" do
    Material.create!(name: "バター", user: @user, price: 200.0).tap do |m|
      MaterialQuantity.create!(material: m, unit: @unit_g, count: 100)
    end

    Material.create!(name: "マーガリン", user: @user, price: 150.0).tap do |m|
      MaterialQuantity.create!(material: m, unit: @unit_g, count: 100)
    end

    Material.create!(name: "オリーブオイル", user: @user, price: 300.0).tap do |m|
      MaterialQuantity.create!(material: m, unit: @unit_g, count: 100)
    end

    visit materials_path

    # Search functionality
    fill_in "材料名で検索...", with: "バター"

    assert_text "バター"
    assert_no_text "オリーブオイル"

    # Clear search
    click_on "クリア"

    assert_text "バター"
    assert_text "マーガリン"
    assert_text "オリーブオイル"
  end

end
