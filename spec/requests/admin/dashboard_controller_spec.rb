# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::DashboardController, feature_category: :not_owned do # rubocop:disable RSpec/FeatureCategory -- Controller already marked not_owned
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:organization_owner).user }
  let_it_be(:regular_user) { create(:user) }

  describe 'GET /admin' do
    context 'when user is an instance admin' do
      before do
        sign_in(admin)
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'renders the instance admin dashboard' do
          get admin_root_path

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include(_('Dashboard'))
        end
      end

      context 'when admin mode is not enabled' do
        it 'redirects to admin mode login' do
          get admin_root_path

          expect(response).to redirect_to(new_admin_session_path)
        end
      end
    end

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'denies access' do
        get admin_root_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is a regular user' do
      before do
        sign_in(regular_user)
      end

      it 'denies access' do
        get admin_root_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not authenticated' do
      it 'returns not found' do
        get admin_root_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
