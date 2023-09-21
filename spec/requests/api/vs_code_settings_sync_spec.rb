# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::VsCodeSettingsSync, :aggregate_failures, factory_default: :keep, feature_category: :web_ide do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:user_token) { create(:personal_access_token) }

  shared_examples "returns unauthorized when not authenticated" do
    it 'returns 401 for non-authenticated' do
      get api(path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples "returns 200 when authenticated" do
    it 'returns 200 when authenticated' do
      get api(path, personal_access_token: user_token)
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET /vscode/settings_sync/v1/manifest' do
    let(:path) { "/vscode/settings_sync/v1/manifest" }

    it_behaves_like "returns unauthorized when not authenticated"
    it_behaves_like "returns 200 when authenticated"

    context 'when no settings record is present' do
      it 'returns a session id' do
        get api(path, personal_access_token: user_token)
        expect(json_response).to have_key('latest')
        expect(json_response).to have_key('session')
      end

      it 'returns no latest keys' do
        get api(path, personal_access_token: user_token)
        expect(json_response).to have_key('latest')
        expect(json_response['latest']).not_to have_key('settings')
      end
    end

    context 'when settings record is present' do
      let_it_be(:settings) { create(:vscode_setting) }

      it 'returns the latest keys' do
        get api(path, personal_access_token: user_token)
        expect(json_response).to have_key('latest')
        expect(json_response).to have_key('session')
        expect(json_response['latest']).to have_key('settings')
        expect(json_response.dig('latest', 'settings')).to eq settings.id
      end
    end
  end

  describe 'GET /vscode/settings_sync/v1/resource/machines/latest' do
    let(:path) { "/vscode/settings_sync/v1/resource/machines/latest" }

    it_behaves_like "returns unauthorized when not authenticated"
    it_behaves_like "returns 200 when authenticated"

    it 'returns a list of machines' do
      get api(path, personal_access_token: user_token)
      expect(json_response).to have_key('version')
      expect(json_response).to have_key('machines')
      expect(json_response['machines']).to be_an Array
      expect(json_response['machines'].first).to have_key('id')
    end
  end

  describe 'GET /vscode/settings_sync/v1/resource/:resource_name/:id' do
    let(:path) { "/vscode/settings_sync/v1/resource/settings/1" }

    it_behaves_like "returns 200 when authenticated"
    it_behaves_like "returns unauthorized when not authenticated"

    context 'when settings with that type are not present' do
      it 'returns settings with empty json content' do
        get api(path, personal_access_token: user_token)
        expect(json_response).to have_key('content')
        expect(json_response).to have_key('version')
        expect(json_response['content']).to eq('{}')
      end
    end

    context 'when settings with that type are present' do
      let_it_be(:settings) { create(:vscode_setting, content: '{ "key": "value" }') }

      it 'returns settings with the correct json content' do
        get api(path, personal_access_token: user_token)
        expect(json_response).to have_key('content')
        expect(json_response).to have_key('version')
        expect(json_response['content']).to eq('{ "key": "value" }')
      end
    end
  end

  describe 'POST /vscode/settings_sync/v1/resource/:resource_name' do
    let(:path) { "/vscode/settings_sync/v1/resource/settings" }

    subject(:request) do
      post api(path, personal_access_token: user_token), params: { content: '{ "editor.fontSize": 12 }' }
    end

    it 'returns unauthorized when not authenticated' do
      post api(path)
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 201 when a valid request is sent' do
      request

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'creates a new record for the setting when the setting is not present' do
      expect { request }.to change { User.find(user.id).vscode_settings.count }.from(0).to(1)
      record = User.find(user.id).vscode_settings.by_setting_type('settings').first
      expect(record.content).to eq('{ "editor.fontSize": 12 }')
    end

    it 'updates a record if the setting is already present' do
      create(:vscode_setting)
      expect { request }.not_to change { User.find(user.id).vscode_settings.count }
      record = User.find(user.id).vscode_settings.by_setting_type('settings').first
      expect(record.content).to eq('{ "editor.fontSize": 12 }')
    end

    it 'fails if required fields not passed' do
      post api(path, personal_access_token: user_token), params: {}
      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end
