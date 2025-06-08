require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up" do
    visit new_user_registration_path

    fill_in "メールアドレス", with: "newuser@example.com"
    fill_in "パスワード", with: "password123"
    fill_in "パスワード（確認）", with: "password123"

    click_button "登録"

    assert_text "Welcome! You have signed up successfully."
    assert_current_path products_path
  end

  test "user can sign in and sign out" do
    user = User.create!(
      email: "existing@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    visit root_path

    fill_in "メールアドレス", with: "existing@example.com"
    fill_in "パスワード", with: "password123"

    click_button "ログイン"

    assert_text "Signed in successfully."
    # Deviseはroot_pathにリダイレクトし、その後productsへリダイレクトされる
    assert_current_path root_path

    # Sign out
    click_on "ログアウト"

    assert_text "Signed out successfully."
    assert_current_path root_path
  end

  test "user can update settings including cost rate" do
    user = User.create!(
      email: "settings@example.com",
      password: "password123",
      password_confirmation: "password123",
      profit_ratio: 0.3
    )

    sign_in_as(user)

    click_on "設定"

    assert_text "設定の編集"
    assert_field "原価率（小数）", with: "0.3"

    fill_in "原価率（小数）", with: "0.25"
    fill_in "現在のパスワード", with: "password123"

    click_button "更新"

    assert_text "Your account has been updated successfully."

    # Verify the change persisted
    click_on "設定"
    assert_field "原価率（小数）", with: "0.25"
  end
end
