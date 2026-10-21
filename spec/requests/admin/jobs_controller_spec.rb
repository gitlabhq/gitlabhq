# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::JobsController, feature_category: :continuous_integration do
  describe 'GET #index' do
    context 'with an authenticated admin user', :enable_admin_mode do
      it 'renders the index for an admin' do
        sign_in(create(:admin))

        get admin_jobs_path

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'without admin access' do
      it 'returns `not_found`' do
        sign_in(create(:user))

        get admin_jobs_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
