# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WebCommits, :clean_gitlab_redis_cache, feature_category: :source_code_management do
  describe 'GET /web_commits/public_key' do
    context 'when Gitaly is available' do
      let(:public_key) { 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFcykDaUT7x4oXyUCfgqJhfAXRbhtsLl4fi4142zrPCI' }

      before do
        allow_next_instance_of(::Gitlab::GitalyClient::ServerService) do |instance|
          allow(instance).to receive_message_chain(:server_signature, :public_key).and_return(public_key)
        end
      end

      context 'and the public key is not found' do
        let(:public_key) { '' }

        it 'returns not found' do
          get api('/web_commits/public_key')

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('Public key not found.')
        end

        it 'does not cache the public key' do
          expect(Rails.cache).not_to receive(:fetch).with(
            described_class::GITALY_PUBLIC_KEY_CACHE_KEY, expires_in: 1.hour.to_i, skip_nil: true
          ).and_call_original

          get api('/web_commits/public_key')
        end
      end

      context 'and the public key is found' do
        it 'returns the public key' do
          get api('/web_commits/public_key')

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['public_key']).to eq(public_key)
        end

        it 'caches the public key' do
          expect(Rails.cache).to receive(:fetch).with(
            described_class::GITALY_PUBLIC_KEY_CACHE_KEY, expires_in: 1.hour.to_i, skip_nil: true
          ).and_call_original

          get api('/web_commits/public_key')
        end
      end
    end

    context 'when Gitaly is unavailable' do
      before do
        allow_next_instance_of(::Gitlab::GitalyClient::ServerService) do |instance|
          allow(instance).to receive(:server_signature).and_raise(GRPC::Unavailable)
        end
      end

      it 'does not cache the public key' do
        expect(Rails.cache).not_to receive(:fetch).with(
          described_class::GITALY_PUBLIC_KEY_CACHE_KEY, expires_in: 1.hour.to_i, skip_nil: true
        ).and_call_original

        get api('/web_commits/public_key')
      end

      it 'returns service unavailable' do
        get api('/web_commits/public_key')

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(json_response['message'])
          .to eq('The git server, Gitaly, is not available at this time. Please contact your administrator.')
      end
    end
  end
end
