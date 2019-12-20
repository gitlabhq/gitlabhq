# frozen_string_literal: true

# Helper for enabling admin mode in tests

module AdminModeHelper
  # Administrators are logged in by default in user mode and have to switch to admin
  # mode for accessing any administrative functionality. This helper lets a user
  # be in admin mode without requiring a second authentication step (provided
  # the user is an admin)
  def enable_admin_mode!(user)
    fake_user_mode = instance_double(Gitlab::Auth::CurrentUserMode)

    allow(Gitlab::Auth::CurrentUserMode).to receive(:new).with(user).and_return(fake_user_mode)
    allow(fake_user_mode).to receive(:admin_mode?).and_return(user&.admin?)
  end
end
