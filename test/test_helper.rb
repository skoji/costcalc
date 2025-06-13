ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper method to create users with password for tests
    def create_test_user(email: "test@example.com", password: "password123")
      User.create!(
        email: email,
        password: password,
        password_confirmation: password
      )
    end

    # Helper method to temporarily set environment variables during tests
    def with_env(new_env)
      old_env = ENV.to_hash
      new_env.each { |key, value| ENV[key] = value }
      yield
    ensure
      ENV.replace(old_env)
    end
  end
end
