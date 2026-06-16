# frozen_string_literal: true

require 'spec_helper'

module SignUpHelpers
  def fill_in_sign_up_form(new_user, invite: false)
    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email unless invite
    fill_in 'new_user_password', with: new_user.password

    expect_username_to_be_validated

    yield if block_given?

    click_button _('Continue')
  end

  def confirm_email(new_user)
    new_user_token = User.find_by_email(new_user.email).confirmation_token

    visit user_confirmation_path(confirmation_token: new_user_token)
  end

  # Waits until a User record with the given email is persisted. Useful
  # after a signup form submission to avoid racing the still-in-flight
  # server request.
  def wait_for_user_to_be_created(email)
    wait_for('user to be created') { User.exists?(email: email) }
  end

  private

  def expect_username_to_be_validated
    expect(page).to have_selector('[data-testid="new-user-username-field"].gl-field-success-outline')
  end
end

SignUpHelpers.prepend_mod_with('SignUpHelpers')
