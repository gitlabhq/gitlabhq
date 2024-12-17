# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::VsCode::Settings::VsCodeSettingsSync, :aggregate_failures, factory_default: :keep, feature_category: :web_ide do
  include GrapePathHelpers::NamedRouteMatcher

  let_it_be(:user) { create_default(:user) }
  let_it_be(:user_token) { create(:personal_access_token) }

  shared_examples "returns unauthorized when not authenticated" do
    it 'returns 401 for non-authenticated' do
      get api(path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples "returns 20x when authenticated" do |http_status|
    it "returns #{http_status || :ok} when authenticated" do
      get api(path, personal_access_token: user_token)
      expect(response).to have_gitlab_http_status(http_status || :ok)
    end
  end

  shared_examples "returns 400" do
    it 'returns 400' do
      get api(path, personal_access_token: user_token)

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'GET /vscode/settings_sync/v1/manifest' do
    let(:path) { "/vscode/settings_sync/v1/manifest" }

    it_behaves_like "returns unauthorized when not authenticated"
    it_behaves_like "returns 20x when authenticated"

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

      it 'includes default machine id' do
        get api(path, personal_access_token: user_token)
        expect(json_response['latest']).to have_key('machines')
      end
    end

    context 'when settings record is present' do
      let_it_be(:settings) { create(:vscode_setting) }

      it 'returns the latest keys' do
        get api(path, personal_access_token: user_token)
        expect(json_response).to have_key('latest')
        expect(json_response).to have_key('session')
        expect(json_response['latest']).to have_key('settings')
        expect(json_response.dig('latest', 'settings')).to eq settings.uuid
      end
    end
  end

  describe 'GET /vscode/settings_sync/v1/resource/machines/latest' do
    let(:path) { "/vscode/settings_sync/v1/resource/machines/latest" }

    it_behaves_like "returns unauthorized when not authenticated"
    it_behaves_like "returns 20x when authenticated"

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

    it_behaves_like "returns 20x when authenticated", :no_content
    it_behaves_like "returns unauthorized when not authenticated"

    context "when resource type is invalid" do
      let(:path) { "/vscode/settings_sync/v1/resource/foo/1" }

      it_behaves_like "returns 400"
    end

    context 'when settings with that type are not present' do
      it 'returns 204 no content and no content ETag header' do
        get api(path, personal_access_token: user_token)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.header['ETag']).to eq(::VsCode::Settings::NO_CONTENT_ETAG)
      end
    end

    context 'when settings with that type are present' do
      let_it_be(:settings) { create(:vscode_setting, content: '{ "key": "value" }') }

      it 'returns settings with the correct json content' do
        get api(path, personal_access_token: user_token)
        expect(json_response).to have_key('content')
        expect(json_response).to have_key('version')
        expect(json_response).to have_key('machineId')
        expect(json_response['content']).to eq('{ "key": "value" }')
      end
    end

    context "when extension settings are present" do
      let_it_be(:extensions_settings) do
        create(:vscode_setting, setting_type: 'extensions', settings_context_hash: '5678',
          content: '{ "key": "extensions_value" }')
      end

      let_it_be(:another_extensions_settings) do
        create(:vscode_setting, setting_type: 'extensions', settings_context_hash: '1234',
          content: '{ "key": "another_extensions_value" }')
      end

      let_it_be(:extensions_settings_no_settings_context_hash) do
        create(:vscode_setting, setting_type: 'extensions',
          content: '{ "key": "extensions_no_settings_context_hash_value" }')
      end

      it "returns latest settings based on settings_context_hash if latest resource is requested" do
        path = "/vscode/settings_sync/1234/v1/resource/extensions/latest"
        get api(path, personal_access_token: user_token)
        expect(json_response['content']).to eq(another_extensions_settings.content)
      end

      it "returns latest setting based on settings_context_hash if id is 0" do
        path = "/vscode/settings_sync/1234/v1/resource/extensions/0"
        get api(path, personal_access_token: user_token)
        expect(json_response['content']).to eq(another_extensions_settings.content)
      end

      it "returns correct setting if no settings_context_hash is passed" do
        path = "/vscode/settings_sync/v1/resource/extensions/1"
        get api(path, personal_access_token: user_token)
        expect(json_response['content']).to eq(extensions_settings_no_settings_context_hash.content)
      end
    end
  end

  describe 'GET /vscode/settings_sync/v1/resource/:resource_name/' do
    let(:path) { "/vscode/settings_sync/v1/resource/settings/" }

    context "when resource type is invalid" do
      let(:path) { "/vscode/settings_sync/v1/resource/foo" }

      it_behaves_like "returns 400"
    end

    it_behaves_like "returns unauthorized when not authenticated"
    it_behaves_like "returns 20x when authenticated", :ok

    context 'when settings with that type are not present' do
      it "returns empty array response" do
        get api(path, personal_access_token: user_token)

        expect(json_response.length).to eq(0)
      end
    end

    context 'when settings with that type are present' do
      let_it_be(:settings) { create(:vscode_setting, content: '{ "key": "value" }') }

      it 'returns settings with the correct json content' do
        get api(path, personal_access_token: user_token)

        setting_type = settings[:setting_type]
        uuid = settings[:uuid]

        resource_ref = "/api/v4/vscode/settings_sync/v1/resource/#{setting_type}/#{uuid}"

        expect(json_response.length).to eq(1)
        expect(json_response.first['url']).to eq(resource_ref)
        expect(json_response.first['created']).to eq(settings.updated_at.to_i)
      end
    end

    context 'when settings with that type are present with settings_context_hash' do
      let(:settings_context_hash) { '1234' }
      let(:path) { "/vscode/settings_sync/#{settings_context_hash}/v1/resource/settings/" }
      let_it_be(:settings) { create(:vscode_setting, content: '{ "key": "value" }') }

      it 'returns settings with the correct json content' do
        get api(path, personal_access_token: user_token)

        setting_type = settings[:setting_type]
        uuid = settings[:uuid]

        resource_ref = "/api/v4/vscode/settings_sync/#{settings_context_hash}/v1/resource/#{setting_type}/#{uuid}"

        expect(json_response.length).to eq(1)
        expect(json_response.first['url']).to eq(resource_ref)
        expect(json_response.first['created']).to eq(settings.updated_at.to_i)
      end
    end

    context 'when setting type is machine' do
      let(:path) { "/vscode/settings_sync/v1/resource/machines/" }

      it 'created field is nil' do
        get api(path, personal_access_token: user_token)

        expect(json_response.length).to eq(1)
        expect(json_response.first['created']).to be_nil
      end
    end
  end

  describe 'POST /vscode/settings_sync/v1/resource/:resource_name' do
    let(:path) { "/vscode/settings_sync/v1/resource/settings" }

    subject(:request) do
      post api(path, personal_access_token: user_token), params: { content: '{ "editor.fontSize": 12 }', version: 1 }
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
      record = User.find(user.id).vscode_settings.by_setting_types(['settings']).first
      expect(record.content).to eq('{ "editor.fontSize": 12 }')
    end

    it 'updates a record if the setting is already present' do
      create(:vscode_setting)
      expect { request }.not_to change { User.find(user.id).vscode_settings.count }
      record = User.find(user.id).vscode_settings.by_setting_types(['settings']).first
      expect(record.content).to eq('{ "editor.fontSize": 12 }')
    end

    it 'fails if required fields not passed' do
      post api(path, personal_access_token: user_token), params: {}
      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'DELETE /vscode/settings_sync/v1/collection' do
    let(:path) { "/vscode/settings_sync/v1/collection" }

    subject(:request) do
      delete api(path, personal_access_token: user_token)
    end

    it 'returns unauthorized when not authenticated' do
      delete api(path)
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when user has one or more setting resources' do
      before do
        create(:vscode_setting, setting_type: 'globalState')
        create(:vscode_setting, setting_type: 'extensions')
      end

      it 'deletes all user setting resources' do
        expect { request }.to change { User.find(user.id).vscode_settings.count }.from(2).to(0)
      end
    end
  end
end
