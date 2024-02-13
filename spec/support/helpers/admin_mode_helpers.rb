# frozen_string_literal: true

# Helper for enabling admin mode in tests

module AdminModeHelper
  # Administrators are logged in by default in user mode and have to switch to admin
  # mode for accessing any administrative functionality. This helper lets a user
  # access the admin area in two different ways:
  #
  # * Fast (use_ui: false) and suitable form the most use cases: fakes calls and grants
  # access to the admin area without requiring a second authentication step (provided the
  # user is an admin)
  # * Slow (use_ui: true): visits the admin UI and enters the users password. A second
  # authentication step may be needed.
  #
  # See also tag :enable_admin_mode in spec/spec_helper.rb for a spec-wide
  # alternative
  def enable_admin_mode!(user, use_ui: false)
    if use_ui
      visit new_admin_session_path

      # When JavaScript is enabled, wait for the password field, with class `.js-password`,
      # to be replaced by the Vue passsword component,
      # `app/assets/javascripts/authentication/password/components/password_input.vue`.
      expect(page).not_to have_selector('.js-password') if javascript_test?

      fill_in 'user_password', with: user.password
      click_button 'Enter admin mode'

      wait_for_requests
    else
      fake_user_mode = instance_double(Gitlab::Auth::CurrentUserMode)

      allow(Gitlab::Auth::CurrentUserMode).to receive(:new).and_call_original

      allow(Gitlab::Auth::CurrentUserMode).to receive(:new).with(user).and_return(fake_user_mode)
      allow(fake_user_mode).to receive(:admin_mode?).and_return(user&.admin?)
    end
  end
end
