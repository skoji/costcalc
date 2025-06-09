module ApplicationHelper
  def user_registration_enabled?
    ENV.fetch("DISABLE_USER_REGISTRATION", "false").downcase != "true"
  end
end
