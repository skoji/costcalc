require "test_helper"

class FlashMessageTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_test_user(email: "flash_test@example.com")
    @unit_g = Unit.create!(name: "g", user: @user)
    @material = Material.create!(name: "バター", price: 500.0, user: @user)
    MaterialQuantity.create!(
      material: @material,
      unit: @unit_g,
      count: 1.0
    )
  end

  test "flash messages are displayed in English during tests" do
    # English environment (test environment)
    assert_equal :en, I18n.locale

    # Sign in
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }

    # Test material creation flash message
    post materials_path, params: {
      material_form: {
        material_name: "Test Material",
        material_price: 100.0,
        material_quantities_attributes: {
          "0" => {
            material_count: 1.0,
            unit_id: @unit_g.id
          }
        }
      }
    }

    follow_redirect!
    assert_includes response.body, "Material was successfully created."
  end

  test "flash message translation keys work correctly" do
    # Test that translation keys resolve correctly
    with_locale(:en) do
      assert_equal "Material was successfully created.", I18n.t("flash.material.created")
      assert_equal "Product was successfully updated.", I18n.t("flash.product.updated")
    end

    with_locale(:ja) do
      assert_equal "材料が作成されました。", I18n.t("flash.material.created")
      assert_equal "製品が更新されました。", I18n.t("flash.product.updated")
    end
  end

  private

  def with_locale(locale)
    original_locale = I18n.locale
    I18n.locale = locale
    yield
  ensure
    I18n.locale = original_locale
  end
end
