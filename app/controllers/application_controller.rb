class ApplicationController < SharedController
  # Abstract Controller for the App pages
  # implicitly uses the 'application' layout

  include Pundit

  before_action :authenticate_user!

  def authenticate_admin!
    current_user.is_admin? || not_found
  end

  ## Devise overrides
  # See also RegistrationsController::after_sign_up_path_for
  def after_sign_in_path_for(resource_or_scope)
    if resource_or_scope.sign_in_count == 1
      path = tutoriels_path
    else
      path = quo_needs_path
    end
    stored_location_for(resource_or_scope) || path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
