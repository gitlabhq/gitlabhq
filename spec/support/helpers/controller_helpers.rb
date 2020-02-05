# frozen_string_literal: true

module ControllerHelpers
  # It seems Devise::Test::ControllerHelpers#sign_in doesn't clear out the @current_user
  # variable of the controller, hence it's not overwritten on retries.
  # This should be fixed in Devise:
  #   - https://github.com/heartcombo/devise/issues/5190
  #   - https://github.com/heartcombo/devise/pull/5191
  def sign_in(resource, deprecated = nil, scope: nil)
    super

    scope ||= Devise::Mapping.find_scope!(resource)

    @controller.instance_variable_set(:"@current_#{scope}", nil)
  end
end

Devise::Test::ControllerHelpers.prepend(ControllerHelpers)
