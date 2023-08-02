# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  shared_examples 'action disabled by `ui_for_organizations` feature flag' do
    before do
      stub_feature_flags(ui_for_organizations: false)
    end

    it 'renders 404' do
      gitlab_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'basic organization controller action' do
    before do
      sign_in(user)
    end

    context 'when the user does not have authorization' do
      let_it_be(:user) { create(:user) }

      it 'renders 404' do
        gitlab_request

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like 'action disabled by `ui_for_organizations` feature flag'
    end

    context 'when the user has authorization', :enable_admin_mode do
      let_it_be(:user) { create(:admin) }

      it 'renders 200 OK' do
        gitlab_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it_behaves_like 'action disabled by `ui_for_organizations` feature flag'
    end
  end

  describe 'GET #show' do
    subject(:gitlab_request) { get organization_path(organization) }

    it_behaves_like 'basic organization controller action'
  end

  describe 'GET #groups_and_projects' do
    subject(:gitlab_request) { get groups_and_projects_organization_path(organization) }

    it_behaves_like 'basic organization controller action'
  end
end
