# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketImport::ClientFactory, feature_category: :importers do
  describe '.for' do
    subject(:client) { described_class.for(project) }

    context 'with OAuth credentials' do
      let_it_be(:project) do
        create(:project, :import_started,
          import_url: 'https://bitbucket.org/repo/repo.git',
          import_data_attributes: {
            credentials: { token: 'token-1', refresh_token: 'refresh-1', expires_at: 1.hour.ago.to_i, expires_in: 7200 }
          }
        )
      end

      before do
        provider = Struct.new(:app_id, :app_secret).new('app-id', 'app-secret')
        allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('bitbucket').and_return(provider)
      end

      it 'returns a Bitbucket::Client' do
        expect(client).to be_a(Bitbucket::Client)
      end

      it 'passes the provider OAuth credentials to the client' do
        expect(Bitbucket::Client).to receive(:new)
          .with(hash_including(app_id: 'app-id', app_secret: 'app-secret'), any_args)

        client
      end

      it 'delegates refresh! to a TokenRefreshStrategy bound to the project' do
        expect_next_instance_of(Import::BitbucketImport::TokenRefreshStrategy, project) do |strategy|
          expect(strategy).to receive(:refresh)
        end

        client.connection.refresh!
      end
    end

    context 'with API token credentials' do
      let_it_be(:project) do
        create(:project, :import_started,
          import_url: 'https://bitbucket.org/repo/repo.git',
          import_data_attributes: { credentials: { email: 'user@example.com', api_token: 'api-token' } }
        )
      end

      context 'when the Bitbucket OAuth provider is not configured' do
        before do
          allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('bitbucket').and_return(nil)
        end

        it 'builds an API connection without OAuth credentials', :aggregate_failures do
          expect(Bitbucket::Client).to receive(:new)
            .with(hash_excluding(:app_id, :app_secret), any_args)
            .and_call_original

          expect(client.connection.connection).to be_a(Bitbucket::ApiConnection)
        end
      end
    end
  end
end
