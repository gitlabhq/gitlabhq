# frozen_string_literal: true

shared_examples 'instance statistics availability' do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    stub_application_setting(usage_ping_enabled: true)
  end

  describe 'GET #index' do
    it 'is available when the feature is available publicly' do
      get :index

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'renders a 404 when the feature is not available publicly' do
      stub_application_setting(instance_statistics_visibility_private: true)

      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'for admins' do
      let(:user) { create(:admin) }

      it 'allows access when the feature is not available publicly' do
        stub_application_setting(instance_statistics_visibility_private: true)

        get :index

        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end
end
