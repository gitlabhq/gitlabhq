# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketImport::TokenRefreshStrategy, feature_category: :importers do
  include ExclusiveLeaseHelpers

  let_it_be(:initial_bitbucket_credentials) do
    {
      user: 'x-token-auth',
      password: 'token-1',
      token: 'token-1',
      expires_at: 1.hour.ago.to_i,
      expires_in: 7200,
      refresh_token: 'refresh-1'
    }.freeze
  end

  let_it_be(:project, reload: true) do
    create(:project, :import_started,
      import_url: 'https://bitbucket.org/repo/repo.git',
      import_data_attributes: { credentials: initial_bitbucket_credentials }
    )
  end

  let(:strategy) { described_class.new(project) }
  let(:connection) do
    Bitbucket::OauthConnection.new(
      initial_bitbucket_credentials, app_id: '', app_secret: '', refresh_strategy: strategy
    )
  end

  before do
    stub_exclusive_lease("bitbucket-import:refresh:#{project.id}", 'uuid', timeout: described_class::LOCK_TTL)
  end

  describe '#refresh' do
    let(:refresh_response) do
      instance_double(
        OAuth2::AccessToken,
        token: 'token-2', refresh_token: 'refresh-2',
        expires_at: 1.hour.from_now.to_i, expires_in: 7200
      )
    end

    it 'serializes the refresh inside an exclusive lease keyed by project id' do
      allow_next_instance_of(OAuth2::AccessToken) do |oauth_token|
        allow(oauth_token).to receive_messages(refresh!: refresh_response, expired?: true)
      end

      expect(strategy).to receive(:in_lock)
        .with("bitbucket-import:refresh:#{project.id}",
          ttl: described_class::LOCK_TTL,
          retries: described_class::LOCK_RETRIES,
          sleep_sec: described_class::LOCK_SLEEP)
        .and_call_original

      strategy.refresh(connection)
    end

    context 'when the token rotates' do
      before do
        allow_next_instance_of(OAuth2::AccessToken) do |oauth_token|
          allow(oauth_token).to receive_messages(refresh!: refresh_response, expired?: true)
        end
      end

      it 'persists the new credentials and updates the import URL', :aggregate_failures do
        strategy.refresh(connection)

        project.import_data.reload

        expect(project.import_data.credentials).to include(
          token: 'token-2',
          refresh_token: 'refresh-2',
          password: 'token-2'
        )
        expect(project.reload.unsafe_import_url).to include('x-token-auth:token-2@')
      end
    end

    context 'when another worker has already persisted a fresh refresh_token' do
      before do
        project.import_data.update!(
          credentials: initial_bitbucket_credentials.merge(
            token: 'token-rotated',
            refresh_token: 'refresh-rotated',
            expires_at: 1.hour.from_now.to_i,
            password: 'token-rotated'
          )
        )
      end

      it 'adopts the rotated credentials and skips the Bitbucket API call', :aggregate_failures do
        expect(connection).not_to receive(:perform_refresh!)

        strategy.refresh(connection)

        expect(connection.token).to eq('token-rotated')
        expect(connection.refresh_token).to eq('refresh-rotated')
      end
    end

    context 'when import_data has no credentials' do
      before do
        project.import_data.update_columns(encrypted_credentials: nil, encrypted_credentials_iv: nil)

        allow_next_instance_of(OAuth2::AccessToken) do |oauth_token|
          allow(oauth_token).to receive_messages(refresh!: refresh_response, expired?: true)
        end
      end

      it 'logs a warning, refreshes with the in-memory token, and skips persistence', :aggregate_failures do
        expect(Gitlab::BitbucketImport::Logger).to receive(:warn).with(
          hash_including(
            message: /credentials missing on import_data/,
            project_id: project.id
          )
        )
        expect(connection).to receive(:perform_refresh!).and_call_original
        expect(project.import_data).not_to receive(:update!)

        strategy.refresh(connection)
      end
    end

    context 'when the refreshed token matches what was already persisted' do
      before do
        allow_next_instance_of(OAuth2::AccessToken) do |oauth_token|
          response = instance_double(
            OAuth2::AccessToken,
            token: 'token-1', refresh_token: 'refresh-1',
            expires_at: 1.hour.from_now.to_i, expires_in: 7200
          )
          allow(oauth_token).to receive_messages(refresh!: response, expired?: true)
        end
      end

      it 'does not write to import_data' do
        expect(project.import_data).not_to receive(:update!)

        strategy.refresh(connection)
      end
    end
  end
end
