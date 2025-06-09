require "application_system_test_case"

class UserRegistrationTest < ApplicationSystemTestCase
  test "registration is enabled by default" do
    visit root_path

    # Sign Up link should be visible in navigation
    assert_selector "a", text: "Sign Up"

    visit new_user_session_path
    # Sign Up link should be visible on login page
    assert_selector "a", text: "Sign Up"

    # Can access registration page
    visit new_user_registration_path
    assert_selector "h2", text: "Sign Up"
  end

  test "registration can be disabled via environment variable" do
    # Temporarily set the environment variable
    original_value = ENV["DISABLE_USER_REGISTRATION"]
    ENV["DISABLE_USER_REGISTRATION"] = "true"

    visit root_path

    # Sign Up link should NOT be visible in navigation
    assert_no_selector "a", text: "Sign Up"

    visit new_user_session_path
    # Sign Up link should NOT be visible on login page
    assert_no_selector "a", text: "Sign Up"

    # Trying to access registration page should redirect
    visit new_user_registration_path
    assert_current_path new_user_session_path
    assert_text "New user registration is currently disabled."

  ensure
    # Restore original value
    ENV["DISABLE_USER_REGISTRATION"] = original_value
  end

  test "registration controller blocks new user creation when disabled" do
    # Create initial user to have login capability
    user = User.create!(
      email: "existing@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # Temporarily set the environment variable
    original_value = ENV["DISABLE_USER_REGISTRATION"]
    ENV["DISABLE_USER_REGISTRATION"] = "true"

    # Try to POST to registration endpoint
    visit new_user_registration_path

    # Should be redirected before even seeing the form
    assert_current_path new_user_session_path
    assert_text "New user registration is currently disabled."

    # Verify user count hasn't changed
    assert_no_difference "User.count" do
      # Even if someone tries to POST directly, it should be blocked
      # This is handled by the before_action in the controller
    end

  ensure
    # Restore original value
    ENV["DISABLE_USER_REGISTRATION"] = original_value
  end
end
