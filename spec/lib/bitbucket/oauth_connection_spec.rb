# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::OauthConnection, feature_category: :integrations do
  let(:token) { 'token' }

  # rubocop:disable RSpec/VerifiedDoubles -- existing code moved to a new file
  before do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:provider).and_return(double(app_id: '', app_secret: ''))
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
        expect(instance).to receive(:get).and_return(double(parsed: true))
      end

      connection = described_class.new({ token: token })

      connection.get('/users')
    end

    context 'when the API returns a retryable error' do
      let(:oauth2_error) do
        faraday_response = double(Faraday::Response, status: 429, headers: {}, body: 'some error')
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
        faraday_response = double(Faraday::Response, status: 500, headers: {}, body: 'Internal Server Error')
        allow(faraday_response).to receive(:on_complete)

        OAuth2::Error.new(OAuth2::Response.new(faraday_response))
      end

      before do
        stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      it 'retries the refresh and succeeds if the next attempt works' do
        call_count = 0
        refresh_response = double(token: 'new_token', expires_at: nil, expires_in: nil, refresh_token: nil)

        allow_next_instance_of(OAuth2::AccessToken) do |instance|
          allow(instance).to receive_messages(expired?: true, get: double(parsed: { 'user' => 'test' }))
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
      response = double(token: token, expires_at: nil, expires_in: nil, refresh_token: nil)

      expect_next_instance_of(OAuth2::AccessToken) do |instance|
        expect(instance).to receive(:refresh!).and_return(response)
      end

      described_class.new({ token: token }).refresh!
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end
