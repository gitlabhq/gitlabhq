# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::PublicKeysController, feature_category: :integrations do
  describe 'GET /-/jira_connect/public_keys/:uuid' do
    let(:uuid) { non_existing_record_id }
    let(:public_key_storage_enabled) { true }

    before do
      stub_application_setting(jira_connect_public_key_storage_enabled: public_key_storage_enabled)
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

      context 'when public key storage setting disabled' do
        let(:public_key_storage_enabled) { false }

        it 'renders 404' do
          get jira_connect_public_key_path(id: uuid)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
