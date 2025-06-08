require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |driver_option|
    driver_option.add_argument("--disable-search-engine-choice-screen")
    driver_option.add_argument("--no-sandbox")
    driver_option.add_argument("--disable-dev-shm-usage")
  end

  def setup
    super
    # Force English locale for system tests
    I18n.locale = :en
    I18n.default_locale = :en
  end

  # Helper method to sign in users for system tests
  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Login"
    assert_text "Signed in successfully."
  end
end
