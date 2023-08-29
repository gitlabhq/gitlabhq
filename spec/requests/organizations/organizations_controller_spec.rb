# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  shared_examples 'successful response' do
    it 'renders 200 OK' do
      gitlab_request

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'redirects to sign in page' do
    it 'redirects to sign in page' do
      gitlab_request

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  shared_examples 'action disabled by `ui_for_organizations` feature flag' do
    context 'when `ui_for_organizations` feature flag is disabled' do
      before do
        stub_feature_flags(ui_for_organizations: false)
      end

      it 'renders 404' do
        gitlab_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'when the user is signed in' do
    context 'when the user is signed in' do
      before do
        sign_in(user)
      end

      context 'with no association to an organization' do
        let_it_be(:user) { create(:user) }

        it_behaves_like 'successful response'
        it_behaves_like 'action disabled by `ui_for_organizations` feature flag'
      end

      context 'as as admin', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        it_behaves_like 'successful response'
        it_behaves_like 'action disabled by `ui_for_organizations` feature flag'
      end

      context 'as an organization user' do
        let_it_be(:user) { create :user }

        before do
          create :organization_user, organization: organization, user: user
        end

        it_behaves_like 'successful response'
        it_behaves_like 'action disabled by `ui_for_organizations` feature flag'
      end
    end
  end

  shared_examples 'controller action that requires authentication' do
    context 'when the user is not signed in' do
      it_behaves_like 'redirects to sign in page'

      context 'when `ui_for_organizations` feature flag is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it_behaves_like 'redirects to sign in page'
      end
    end

    it_behaves_like 'when the user is signed in'
  end

  shared_examples 'controller action that does not require authentication' do
    context 'when the user is not logged in' do
      it_behaves_like 'successful response'
      it_behaves_like 'action disabled by `ui_for_organizations` feature flag'
    end

    it_behaves_like 'when the user is signed in'
  end

  describe 'GET #show' do
    subject(:gitlab_request) { get organization_path(organization) }

    it_behaves_like 'controller action that does not require authentication'
  end

  describe 'GET #groups_and_projects' do
    subject(:gitlab_request) { get groups_and_projects_organization_path(organization) }

    it_behaves_like 'controller action that does not require authentication'
  end

  describe 'GET #new' do
    subject(:gitlab_request) { get new_organization_path }

    it_behaves_like 'controller action that requires authentication'
  end

  describe 'GET #index' do
    subject(:gitlab_request) { get organizations_path }

    it_behaves_like 'controller action that requires authentication'
  end
end
