# frozen_string_literal: true

require 'spec_helper'

module SignUpHelpers
  def fill_in_sign_up_form(new_user, submit_button_text = 'Register')
    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email
    fill_in 'new_user_password', with: new_user.password

    wait_for_all_requests

    expect_username_to_be_validated

    yield if block_given?

    click_button submit_button_text
  end

  private

  def expect_username_to_be_validated
    expect(page).to have_selector('[data-testid="new-user-username-field"].gl-field-success-outline')
  end
end
