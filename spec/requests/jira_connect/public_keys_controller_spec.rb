# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::PublicKeysController, feature_category: :integrations do
  describe 'GET /-/jira_connect/public_keys/:uuid' do
    before do
      allow(Gitlab).to receive(:com?).and_return(dot_com)
    end

    let(:uuid) { non_existing_record_id }
    let(:dot_com) { true }

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

      context 'when not on GitLab.com' do
        let(:dot_com) { false }

        it 'renders 404' do
          get jira_connect_public_key_path(id: uuid)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when jira_connect_oauth_self_managed disabled' do
        before do
          stub_feature_flags(jira_connect_oauth_self_managed: false)
        end

        it 'renders 404' do
          get jira_connect_public_key_path(id: uuid)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
