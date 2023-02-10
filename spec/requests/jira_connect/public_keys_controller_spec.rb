# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::PublicKeysController, feature_category: :integrations do
  describe 'GET /-/jira_connect/public_keys/:uuid' do
    let(:uuid) { non_existing_record_id }
    let(:public_key_storage_enabled_config) { true }

    before do
      allow(Gitlab.config.jira_connect).to receive(:enable_public_keys_storage)
        .and_return(public_key_storage_enabled_config)
    end

    it 'renders 404' do
      get jira_connect_public_key_path(id: uuid)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'when public key exists' do
      let_it_be(:public_key) { JiraConnect::PublicKey.create!(key: OpenSSL::PKey::RSA.generate(3072).public_key) }

      let(:uuid) { public_key.uuid }

      it 'renders 200' do
        get jira_connect_public_key_path(id: uuid)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(public_key.key)
      end

      context 'when public key storage config disabled' do
        let(:public_key_storage_enabled_config) { false }

        it 'renders 404' do
          get jira_connect_public_key_path(id: uuid)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'when public key storage setting is enabled' do
          before do
            stub_application_setting(jira_connect_public_key_storage_enabled: true)
          end

          it 'renders 404' do
            get jira_connect_public_key_path(id: uuid)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end
end
