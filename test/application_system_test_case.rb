require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |driver_option|
    driver_option.add_argument("--disable-search-engine-choice-screen")
    driver_option.add_argument("--no-sandbox")
    driver_option.add_argument("--disable-dev-shm-usage")
  end

  def setup
    super
    # Keep default locale (English) for consistent testing
    # UI labels are in Japanese but flash messages will be in English
  end

  # Helper method to sign in users for system tests
  def sign_in_as(user)
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
    assert_text "Signed in successfully."
  end
end
