# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'API Settings - Product Usage Data', :aggregate_failures, :do_not_mock_admin_mode_setting,
  feature_category: :service_ping do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:default_organization) { create(:organization) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    allow(::Organizations::Organization).to receive(:default_organization).and_return(default_organization)
  end

  describe 'GET /application/settings' do
    context 'when authenticated as non-admin' do
      it 'returns forbidden' do
        get api('/application/settings', user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get api('/application/settings')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when environment variable is not set' do
      before do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', nil)
      end

      it 'returns database as the source and the database value' do
        get api('/application/settings', admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['gitlab_product_usage_data_source']).to eq('database')
        expect(json_response).to have_key('gitlab_product_usage_data_enabled')
      end
    end

    context 'when environment variable is set to true' do
      before do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', 'true')
      end

      it 'returns environment as the source and true as the value' do
        get api('/application/settings', admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['gitlab_product_usage_data_source']).to eq('environment')
        expect(json_response['gitlab_product_usage_data_enabled']).to be(true)
      end
    end

    context 'when environment variable is set to false' do
      before do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', 'false')
      end

      it 'returns environment as the source and false as the value' do
        get api('/application/settings', admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['gitlab_product_usage_data_source']).to eq('environment')
        expect(json_response['gitlab_product_usage_data_enabled']).to be(false)
      end
    end
  end
end
