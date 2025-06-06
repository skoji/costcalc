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
  end
end
