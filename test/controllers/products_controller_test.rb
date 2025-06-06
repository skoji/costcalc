require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_test_user(email: "products_controller_test@example.com")
    @unit_g = Unit.create!(name: "g", user: @user)
    @unit_kg = Unit.create!(name: "kg", user: @user)
    @material = Material.create!(name: "バター", price: 500.0, user: @user)
    
    # MaterialQuantityを作成してコスト計算を可能にする
    MaterialQuantity.create!(
      material: @material,
      unit: @unit_kg,
      count: 1.0
    )
    
    @product = Product.create!(
      name: "テストケーキ",
      count: 8.0,
      user: @user
    )
    
    sign_in @user
  end

  test "should get index" do
    get products_url
    assert_response :success
    assert_includes response.body, "製品"
  end

  test "should get new" do
    get new_product_url
    assert_response :success
    assert_includes response.body, "製品新規登録"
  end

  test "should create product" do
    assert_difference('Product.count') do
      post products_url, params: {
        product_form: {
          product_name: "新製品",
          product_count: 6.0,
          product_ingredients_attributes: {
            "0" => {
              material_id: @material.id,
              unit_id: @unit_g.id,
              ingredient_count: 200.0
            }
          }
        }
      }
    end

    product = Product.last
    assert_equal "新製品", product.name
    assert_equal 6.0, product.count
    assert_redirected_to product_path(product)
  end

  test "should add ingredient without creating product" do
    assert_no_difference('Product.count') do
      post products_url, params: {
        commit: "材料追加",
        product_form: {
          product_name: "材料追加テスト",
          product_count: 4.0,
          product_ingredients_attributes: {
            "0" => {
              material_id: @material.id,
              unit_id: @unit_g.id,
              ingredient_count: 150.0
            }
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "材料追加テスト"
  end

  test "should show product" do
    get product_url(@product)
    assert_response :success
    assert_includes response.body, @product.name
  end

  test "should get edit" do
    get edit_product_url(@product)
    assert_response :success
    assert_includes response.body, "製品編集"
  end

  test "should update product" do
    patch product_url(@product), params: {
      product_form: {
        id: @product.id,
        product_name: "更新製品",
        product_count: 10.0,
        product_ingredients_attributes: {
          "0" => {
            material_id: @material.id,
            unit_id: @unit_g.id,
            ingredient_count: 300.0
          }
        }
      }
    }

    @product.reload
    assert_equal "更新製品", @product.name
    assert_equal 10.0, @product.count
    assert_redirected_to product_path(@product)
  end

  test "should destroy product" do
    assert_difference('Product.count', -1) do
      delete product_url(@product)
    end

    assert_redirected_to products_path
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password123'
      }
    }
  end
end