# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::OauthConnection, feature_category: :importers do
  let(:token) { 'token' }

  before do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:provider).and_return(
        GitlabSettings::Options.build({ 'app_id' => '', 'app_secret' => '' })
      )
    end
  end

  describe '#get' do
    it 'calls OAuth2::AccessToken::get' do
      expected_client_options = {
        site: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['site'],
        authorize_url: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['authorize_url'],
        token_url: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['token_url']
      }

      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:retry_with_exponential_backoff).and_call_original
      end

      expect(OAuth2::Client)
        .to receive(:new)
        .with(anything, anything, expected_client_options)

      expect_next_instance_of(OAuth2::AccessToken) do |instance|
        expect(instance).to receive(:get).and_return(instance_double(OAuth2::Response, parsed: true))
      end

      connection = described_class.new({ token: token })

      connection.get('/users')
    end

    context 'when the API returns a retryable error' do
      let(:oauth2_error) do
        faraday_response = instance_double(Faraday::Response, status: 429, headers: {}, body: 'some error')
        allow(faraday_response).to receive(:on_complete)

        OAuth2::Error.new(OAuth2::Response.new(faraday_response))
      end

      before do
        allow_next_instance_of(OAuth2::AccessToken) do |instance|
          allow(instance).to receive(:get).and_raise(oauth2_error)
        end

        stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      it 'logs the retries and raises an error if it does not succeed on retry' do
        expect(Gitlab::BitbucketImport::Logger).to receive(:info)
          .with(message: /Retrying in .+ seconds due to/)
          .twice

        connection = described_class.new({ token: token })

        expect { connection.get('/users') }.to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
      end
    end

    context 'when token refresh raises a transient error' do
      let(:oauth2_error) do
        faraday_response = instance_double(Faraday::Response, status: 500, headers: {}, body: 'Internal Server Error')
        allow(faraday_response).to receive(:on_complete)

        OAuth2::Error.new(OAuth2::Response.new(faraday_response))
      end

      before do
        stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      it 'retries the refresh and succeeds if the next attempt works' do
        call_count = 0
        refresh_response = instance_double(
          OAuth2::AccessToken, token: 'new_token', expires_at: nil, expires_in: nil, refresh_token: nil
        )

        allow_next_instance_of(OAuth2::AccessToken) do |instance|
          allow(instance).to receive_messages(
            expired?: true, get: instance_double(OAuth2::Response, parsed: { 'user' => 'test' })
          )
          allow(instance).to receive(:refresh!) do
            call_count += 1
            raise oauth2_error if call_count == 1

            refresh_response
          end
        end

        connection = described_class.new({ token: token, expires_at: 1.hour.ago.to_i })

        expect(connection.get('/users')).to eq({ 'user' => 'test' })
      end
    end
  end

  describe '#get_response_code' do
    context 'when the request succeeds' do
      it 'returns the HTTP status code as an integer' do
        oauth_response = instance_double(OAuth2::Response, status: 200, parsed: {})

        allow_next_instance_of(OAuth2::AccessToken) do |instance|
          allow(instance).to receive_messages(get: oauth_response, expired?: false)
        end

        connection = described_class.new({ token: token })

        expect(connection.get_response_code('/repositories/workspace/repo/issues')).to eq(200)
      end
    end

    context 'when the request returns a non-retryable error status' do
      it 'returns the HTTP status code from the error' do
        faraday_response = instance_double(Faraday::Response, status: 404, headers: {}, body: 'Not Found')
        allow(faraday_response).to receive(:on_complete)
        oauth2_error = OAuth2::Error.new(OAuth2::Response.new(faraday_response))

        allow_next_instance_of(OAuth2::AccessToken) do |instance|
          allow(instance).to receive(:get).and_raise(oauth2_error)
        end

        connection = described_class.new({ token: token })

        expect(connection.get_response_code('/repositories/workspace/repo/issues')).to eq(404)
      end
    end

    context 'when retries are exhausted due to rate limiting' do
      it 'raises RateLimitError' do
        allow_next_instance_of(OAuth2::AccessToken) do |instance|
          allow(instance).to receive(:get).and_raise(Bitbucket::ExponentialBackoff::RateLimitError)
        end

        connection = described_class.new({ token: token })

        expect { connection.get_response_code('/repositories/workspace/repo/issues') }
          .to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
      end
    end
  end

  describe '#expired?' do
    it 'calls connection.expired?' do
      expect_next_instance_of(OAuth2::AccessToken) do |instance|
        expect(instance).to receive(:expired?).and_return(true)
      end

      expect(described_class.new({ token: token }).expired?).to be_truthy
    end
  end

  describe '#refresh!' do
    it 'calls connection.refresh!' do
      response = instance_double(
        OAuth2::AccessToken, token: token, expires_at: nil, expires_in: nil, refresh_token: nil
      )

      expect_next_instance_of(OAuth2::AccessToken) do |instance|
        expect(instance).to receive(:refresh!).and_return(response)
      end

      described_class.new({ token: token }).refresh!
    end

    context 'when a refresh_strategy is provided' do
      let(:refresh_strategy) { instance_double(Import::BitbucketImport::TokenRefreshStrategy) }

      it 'delegates refresh! to the strategy and does not call the API itself' do
        connection = described_class.new({ token: token }, refresh_strategy: refresh_strategy)

        expect(refresh_strategy).to receive(:refresh).with(connection)
        expect(connection).not_to receive(:perform_refresh!)

        connection.refresh!
      end
    end
  end

  describe '#perform_refresh!' do
    it 'rotates the in-memory credentials from the OAuth2 response', :aggregate_failures do
      response = instance_double(
        OAuth2::AccessToken,
        token: 'new-token',
        expires_at: 1.hour.from_now.to_i,
        expires_in: 3600,
        refresh_token: 'new-refresh-token'
      )

      expect_next_instance_of(OAuth2::AccessToken) do |instance|
        expect(instance).to receive(:refresh!).and_return(response)
      end

      connection = described_class.new({ token: token })
      connection.perform_refresh!

      expect(connection.token).to eq('new-token')
      expect(connection.refresh_token).to eq('new-refresh-token')
      expect(connection.expires_at).to eq(response.expires_at)
    end
  end

  describe '#adopt_credentials' do
    it 'overwrites the in-memory credentials and clears the cached OAuth2 token', :aggregate_failures do
      connection = described_class.new({ token: 'old', refresh_token: 'old-refresh' })
      previous_oauth_token = connection.send(:connection)

      connection.adopt_credentials(
        token: 'token-rotated',
        expires_at: 1.hour.from_now.to_i,
        expires_in: 3600,
        refresh_token: 'refresh-rotated'
      )

      expect(connection.token).to eq('token-rotated')
      expect(connection.refresh_token).to eq('refresh-rotated')
      expect(connection.send(:connection)).not_to equal(previous_oauth_token)
    end
  end
end
