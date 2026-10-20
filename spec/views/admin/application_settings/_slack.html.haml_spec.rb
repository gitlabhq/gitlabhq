# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_slack.html.haml', feature_category: :integrations do
  let(:app_settings) { build(:application_setting) }

  before do
    assign(:application_setting, app_settings)
  end

  it 'renders the form correctly', :aggregate_failures do
    render

    expect(rendered).to have_css('h5', text: 'Step 1: Create your GitLab for Slack app')
    expect(rendered).to have_css('h5', text: 'Step 2: Configure the app settings')
    expect(rendered).to have_field('Client ID', type: 'text')
    expect(rendered).to have_field('Client secret', type: 'text')
    expect(rendered).to have_field('Signing secret', type: 'text')
    expect(rendered).to have_field('Verification token', type: 'text')
    expect(rendered).to have_link(
      'Create Slack app',
      href: slack_app_manifest_share_admin_application_settings_path
    )
    expect(rendered).to have_link(
      'Download latest manifest file',
      href: slack_app_manifest_download_admin_application_settings_path
    )
  end

  context 'when GitLab.com', :saas do
    it 'renders the form correctly', :aggregate_failures do
      render

      expect(rendered).to have_css('h5', exact_text: 'Configure the app settings')
      expect(rendered).not_to have_content('Step 1: Create your GitLab for Slack app')
      expect(rendered).not_to have_content('Step 2: Configure the app settings')
      expect(rendered).to have_field('Client ID', type: 'text')
      expect(rendered).to have_field('Client secret', type: 'text')
      expect(rendered).to have_field('Signing secret', type: 'text')
      expect(rendered).to have_field('Verification token', type: 'text')

      expect(rendered).not_to have_link('Create Slack app')
      expect(rendered).not_to have_link('Download latest manifest file')
    end
  end
end
