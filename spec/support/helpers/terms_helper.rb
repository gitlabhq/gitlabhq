# frozen_string_literal: true

module TermsHelper
  def enforce_terms
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    settings = Gitlab::CurrentSettings.current_application_settings
    ApplicationSettings::UpdateService.new(
      settings, nil, terms: 'These are the terms', enforce_terms: true
    ).execute
  end

  def accept_terms(user)
    terms = Gitlab::CurrentSettings.current_application_settings.latest_terms
    Users::RespondToTermsService.new(user, terms).execute(accepted: true)
  end

  def expect_to_be_on_terms_page
    expect(page).to have_current_path terms_path, ignore_query: true
    expect(page).to have_content('Please accept the Terms of Service before continuing.')
  end
end

TermsHelper.prepend_mod
