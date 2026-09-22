# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Your Work dashboard organization-scoped redirect', feature_category: :organization do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user, organization: organization) }

  before do
    login_as(user)
  end

  def org_scoped_prefix
    "/o/#{organization.path}"
  end

  context 'when the organization is not isolated' do
    it 'redirects org-scoped dashboard paths to the global path' do
      get dashboard_projects_path(organization_path: organization.path)

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response.location).not_to include(org_scoped_prefix)
    end

    it 'preserves query parameters' do
      get activity_dashboard_path(organization_path: organization.path, filter: 'starred')

      expect(response).to redirect_to(activity_dashboard_path(filter: 'starred'))
    end

    it 'redirects the top-level dashboard groups action' do
      get dashboard_groups_path(organization_path: organization.path)

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response.location).not_to include(org_scoped_prefix)
    end

    it 'redirects the top-level dashboard activity action' do
      get activity_dashboard_path(organization_path: organization.path)

      expect(response).to redirect_to(activity_dashboard_path)
    end
  end

  context 'when the organization is isolated' do
    let_it_be(:organization) { create(:organization, :isolated) }
    let_it_be(:user) { create(:user, organization: organization) }

    it 'does not redirect to the global path' do
      get activity_dashboard_path(organization_path: organization.path)

      expect(response).not_to have_gitlab_http_status(:redirect)
    end
  end

  context 'when the path is already global' do
    it 'redirects to the global default without an organization prefix' do
      get activity_dashboard_path

      expect(response).not_to have_gitlab_http_status(:redirect)
    end
  end
end
