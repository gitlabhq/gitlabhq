# frozen_string_literal: true

RSpec.shared_examples 'manage applications' do
  let_it_be(:application_name) { 'application foo bar' }
  let_it_be(:application_name_changed) { "#{application_name} changed" }
  let_it_be(:application_redirect_uri) { 'https://foo.bar' }

  context 'when hash_oauth_secrets flag set' do
    before do
      stub_feature_flags(hash_oauth_secrets: true)
    end

    it 'allows user to manage applications', :js do
      visit new_application_path

      expect(page).to have_content 'Add new application'

      fill_in :doorkeeper_application_name, with: application_name
      fill_in :doorkeeper_application_redirect_uri, with: application_redirect_uri
      check :doorkeeper_application_scopes_read_user
      click_on 'Save application'

      validate_application(application_name, 'Yes')
      expect(page).to have_content _('This is the only time the secret is accessible. Copy the secret and store it securely')
      expect(page).to have_link('Continue', href: index_path)

      expect(page).to have_css("button[title=\"Copy secret\"]", text: 'Copy')

      click_on 'Edit'

      application_name_changed = "#{application_name} changed"

      fill_in :doorkeeper_application_name, with: application_name_changed
      uncheck :doorkeeper_application_confidential
      click_on 'Save application'

      validate_application(application_name_changed, 'No')
      expect(page).not_to have_link('Continue')
      expect(page).to have_content _('The secret is only available when you create the application or renew the secret.')

      visit_applications_path

      page.within '.oauth-applications' do
        click_on 'Destroy'
      end
      expect(page.find('.oauth-applications')).not_to have_content 'test_changed'
    end
  end

  context 'when hash_oauth_secrets flag not set' do
    before do
      stub_feature_flags(hash_oauth_secrets: false)
    end

    it 'allows user to manage applications', :js do
      visit new_application_path

      expect(page).to have_content 'Add new application'

      fill_in :doorkeeper_application_name, with: application_name
      fill_in :doorkeeper_application_redirect_uri, with: application_redirect_uri
      check :doorkeeper_application_scopes_read_user
      click_on 'Save application'

      validate_application(application_name, 'Yes')
      expect(page).to have_link('Continue', href: index_path)

      application = Doorkeeper::Application.find_by(name: application_name)
      expect(page).to have_css("button[title=\"Copy secret\"][data-clipboard-text=\"#{application.secret}\"]", text: 'Copy')

      click_on 'Edit'

      application_name_changed = "#{application_name} changed"

      fill_in :doorkeeper_application_name, with: application_name_changed
      uncheck :doorkeeper_application_confidential
      click_on 'Save application'

      validate_application(application_name_changed, 'No')
      expect(page).not_to have_link('Continue')

      visit_applications_path

      page.within '.oauth-applications' do
        click_on 'Destroy'
      end
      expect(page.find('.oauth-applications')).not_to have_content 'test_changed'
    end
  end

  context 'when scopes are blank' do
    it 'returns an error' do
      visit new_application_path

      expect(page).to have_content 'Add new application'

      fill_in :doorkeeper_application_name, with: application_name
      fill_in :doorkeeper_application_redirect_uri, with: application_redirect_uri
      click_on 'Save application'

      expect(page).to have_content("Scopes can't be blank")
    end
  end

  def visit_applications_path
    visit defined?(applications_path) ? applications_path : new_application_path
  end

  def validate_application(name, confidential)
    aggregate_failures do
      expect(page).to have_content name
      expect(page).to have_content 'Application ID'
      expect(page).to have_content 'Secret'
      expect(page).to have_content "Confidential #{confidential}"
    end
  end
end
