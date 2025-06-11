# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/network.html.haml', feature_category: :groups_and_projects do
  let_it_be(:admin) { build_stubbed(:admin) }
  let_it_be(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
  end

  context 'for Git HTTP rate limits' do
    it 'renders the `git_http_rate_limit_unauthenticated` field' do
      render

      expect(rendered).to have_field('application_setting_throttle_unauthenticated_git_http_enabled')
      expect(rendered).to have_field('application_setting_throttle_unauthenticated_git_http_requests_per_period')
      expect(rendered).to have_field('application_setting_throttle_unauthenticated_git_http_period_in_seconds')
    end

    context 'with git_authenticated_http_limit feature flag enabled' do
      before do
        stub_feature_flags(git_authenticated_http_limit: true)
      end

      it 'renders the `git_http_rate_limit_authenticated` field' do
        render

        expect(rendered).to have_field('application_setting_throttle_authenticated_git_http_enabled')
        expect(rendered).to have_field('application_setting_throttle_authenticated_git_http_requests_per_period')
        expect(rendered).to have_field('application_setting_throttle_authenticated_git_http_period_in_seconds')
      end
    end

    context 'with git_authenticated_http_limit feature flag disabled' do
      before do
        stub_feature_flags(git_authenticated_http_limit: false)
      end

      it 'does not render the `git_http_rate_limit_authenticated` field' do
        render

        expect(rendered).not_to have_field('application_setting_throttle_authenticated_git_http_enabled')
        expect(rendered).not_to have_field('application_setting_throttle_authenticated_git_http_requests_per_period')
        expect(rendered).not_to have_field('application_setting_throttle_authenticated_git_http_period_in_seconds')
      end
    end
  end

  context 'for Users API rate limits' do
    it 'renders the reset disclaimer' do
      render

      expect(rendered).to have_content('Set to 0 to disable the limits.')
    end

    it 'renders the users rate limit fields', :aggregate_failures do
      render

      expect(rendered).to have_field('application_setting_users_api_limit_followers')
      expect(rendered).to have_field('application_setting_users_api_limit_following')
      expect(rendered).to have_field('application_setting_users_api_limit_status')
      expect(rendered).to have_field('application_setting_users_api_limit_ssh_keys')
      expect(rendered).to have_field('application_setting_users_api_limit_ssh_key')
      expect(rendered).to have_field('application_setting_users_api_limit_gpg_keys')
      expect(rendered).to have_field('application_setting_users_api_limit_gpg_key')

      expect(rendered).to have_field('application_setting_users_get_by_id_limit')
      expect(rendered).to have_field('application_setting_users_get_by_id_limit_allowlist_raw')
    end
  end

  context 'for Projects API rate limits' do
    it 'renders the project rate limit fields' do
      render

      expect(rendered).to have_field('application_setting_projects_api_rate_limit_unauthenticated')
      expect(rendered).to have_field('application_setting_projects_api_limit')
      expect(rendered).to have_field('application_setting_project_api_limit')
      expect(rendered).to have_field('application_setting_user_projects_api_limit')
      expect(rendered).to have_field('application_setting_user_contributed_projects_api_limit')
      expect(rendered).to have_field('application_setting_user_starred_projects_api_limit')
    end
  end

  context 'for Groups API rate limits' do
    it 'renders the group rate limit fields' do
      render

      expect(rendered).to have_field('application_setting_groups_api_limit')
      expect(rendered).to have_field('application_setting_group_api_limit')
      expect(rendered).to have_field('application_setting_group_projects_api_limit')
    end
  end

  context 'for Organizations API rate limits' do
    it 'renders the organization rate limit fields' do
      render

      expect(rendered).to have_field('application_setting_create_organization_api_limit')
    end
  end

  context 'for Members API rate limit' do
    it 'renders the `members_delete_limit` field' do
      render

      expect(rendered).to have_field('application_setting_members_delete_limit')
    end
  end
end
