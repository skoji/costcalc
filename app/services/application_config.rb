# frozen_string_literal: true

class ApplicationConfig
  def self.user_registration_enabled?
    ENV.fetch("DISABLE_USER_REGISTRATION", "false").downcase != "true"
  end
end
