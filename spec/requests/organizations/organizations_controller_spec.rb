# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  describe 'GET #directory' do
    subject(:gitlab_request) { get directory_organization_path(organization) }

    before do
      sign_in(user)
    end

    context 'when the user does not have authorization' do
      let_it_be(:user) { create(:user) }

      it 'renders 404' do
        gitlab_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user has authorization', :enable_admin_mode do
      let_it_be(:user) { create(:admin) }

      it 'renders 200 OK' do
        gitlab_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when the feature flag `ui_for_organizations` is disabled' do
        it 'renders 404' do
          stub_feature_flags(ui_for_organizations: false)

          gitlab_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
