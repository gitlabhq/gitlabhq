# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organization-scoped URLs naming a mismatched organization', feature_category: :organization do
  # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- groups outside any explicit organization live here
  let_it_be(:default_organization) { create(:organization, :default) }
  # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

  let_it_be(:organization) { create(:organization) }
  let_it_be(:other_organization) { create(:organization) }

  let_it_be(:group) { create(:group, :public, organization: default_organization) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:scoped_group) { create(:group, :public, organization: organization) }

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when the URL names an organization the group does not belong to' do
    it 'returns 404 for a group page' do
      get "/o/#{other_organization.path}/groups/#{group.full_path}"

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for a project page' do
      get "/o/#{other_organization.path}/#{project.full_path}"

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for a group in a non-default organization' do
      get "/o/#{other_organization.path}/groups/#{scoped_group.full_path}"

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 when the named organization does not exist' do
      get "/o/nonexistent-org/groups/#{group.full_path}"

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for non-GET requests' do
      post "/o/#{other_organization.path}/groups/#{group.full_path}/-/preview_markdown", params: { text: 'text' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'responds like a nonexistent path for a group the user cannot read (security)' do
      private_group = create(:group, :private, organization: default_organization)

      get "/o/#{other_organization.path}/groups/#{private_group.full_path}"

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'redirects anonymous users to sign in, like a nonexistent path' do
      sign_out(user)

      get "/o/#{other_organization.path}/groups/#{group.full_path}"

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'when the URL names the organization the group belongs to' do
    it 'renders the page' do
      get "/o/#{organization.path}/groups/#{scoped_group.full_path}"

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'renders the page when the prefix differs only in case' do
      get "/o/#{organization.path.upcase}/groups/#{scoped_group.full_path}"

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
