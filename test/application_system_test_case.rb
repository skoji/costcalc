require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |driver_option|
    driver_option.add_argument("--disable-search-engine-choice-screen")
  end

  # Include Devise test helpers for system tests
  include Warden::Test::Helpers

  def teardown
    Warden.test_reset!
    super
  end
end
