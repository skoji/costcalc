# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_account_update_params, only: [ :update ]

  protected

  # Redirect to products path after sign up
  def after_sign_up_path_for(resource)
    products_path
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :profit_ratio ])
  end
end
