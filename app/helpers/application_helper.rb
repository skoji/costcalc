module ApplicationHelper
  def user_registration_enabled?
    ApplicationConfig.user_registration_enabled?
  end
end
