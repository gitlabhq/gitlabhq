# frozen_string_literal: true

# Helper for enabling admin mode in tests

module AdminModeHelper
  # Preferably use the `:enable_admin_mode` metadata tag for a spec-wide alternative:
  # (see spec/spec_helper.rb):
  #
  # context 'some test that requires admin mode', :enable_admin_mode do ... end
  #
  # Administrators are logged in by default in user mode and have to switch to admin
  # mode for accessing any administrative functionality.
  #
  # This method fakes calls and grants access to the admin area without requiring a
  # second authentication step (provided the user is an admin).
  def enable_admin_mode!(user)
    fake_user_mode = instance_double(Gitlab::Auth::CurrentUserMode)

    allow(Gitlab::Auth::CurrentUserMode).to receive(:new).and_call_original

    allow(Gitlab::Auth::CurrentUserMode).to receive(:new).with(user).and_return(fake_user_mode)
    allow(fake_user_mode).to receive(:admin_mode?).and_return(user&.can_access_admin_area?)
  end

  # This is a slow version of the `enable_admin_mode!` function. When possible, use
  # the `:enable_admin_mode` metadata or `enable_admin_mode!` instead of this method.
  # It visits the admin page and enters the user's password. A second authentication step may be
  # needed.
  def enter_admin_mode(user, with_2fa: false)
    visit new_admin_session_path

    # When JavaScript is enabled, wait for the password field, with class `.js-password`,
    # to be replaced by the Vue password component,
    # `app/assets/javascripts/authentication/password/components/password_input.vue`.
    expect(page).not_to have_selector('.js-password') if javascript_test?

    fill_in 'user_password', with: user.password
    click_button _('Enter admin mode')

    if with_2fa
      expect(page).to have_content(_('Enter verification code'))
    else
      expect(page).to have_content(_('Admin mode is active'))
    end
  end

  # Requires Javascript driver.
  def leave_admin_mode
    find_by_testid('user-menu-toggle').click
    click_link(s_('CurrentUser|Leave Admin Mode'), href: destroy_admin_session_path)
    expect(page).to have_selector('[data-testid="alert-info"]', text: _('Admin mode is inactive.'))
  end
end
