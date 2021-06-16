# frozen_string_literal: true

RSpec.shared_context 'project service Jira context' do
  let(:url) { 'https://jira.example.com' }
  let(:test_url) { 'https://jira.example.com/rest/api/2/serverInfo' }

  def fill_form(disable: false)
    click_active_checkbox if disable

    fill_in 'service_url', with: url
    fill_in 'service_username', with: 'username'
    fill_in 'service_password', with: 'password'
  end
end
