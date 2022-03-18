# frozen_string_literal: true

RSpec.shared_examples 'manage applications' do
  let_it_be(:application_name) { 'application foo bar' }
  let_it_be(:application_name_changed) { "#{application_name} changed" }
  let_it_be(:application_redirect_uri) { 'https://foo.bar' }

  it 'allows user to manage applications', :js do
    visit new_application_path

    expect(page).to have_content 'Add new application'
    expect(find('#doorkeeper_application_expire_access_tokens')).to be_checked

    fill_in :doorkeeper_application_name, with: application_name
    fill_in :doorkeeper_application_redirect_uri, with: application_redirect_uri
    uncheck :doorkeeper_application_expire_access_tokens
    check :doorkeeper_application_scopes_read_user
    click_on 'Save application'

    validate_application(application_name, 'Yes')
    expect(page).to have_link('Continue', href: index_path)

    application = Doorkeeper::Application.find_by(name: application_name)
    expect(page).to have_css("button[title=\"Copy secret\"][data-clipboard-text=\"#{application.secret}\"]", text: 'Copy')

    click_on 'Edit'

    expect(find('#doorkeeper_application_expire_access_tokens')).not_to be_checked

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
