# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::BillingOidcTokenSource, feature_category: :application_instrumentation do
  subject(:token_source) { described_class.new(audience) }

  let(:audience) { 'billing.stgsub.gitlab.net' }
  let(:sa_email) { 'gitlab-webservice@gitlab-project.iam.gserviceaccount.com' }
  let(:access_token) { 'ya29.test-access-token' }
  let(:id_token) { generate_jwt(exp: 1.hour.from_now.to_i) }

  let(:email_uri) do
    "#{described_class::METADATA_BASE_URL}#{described_class::SERVICE_ACCOUNT_EMAIL_PATH}"
  end

  let(:token_uri) do
    "#{described_class::METADATA_BASE_URL}#{described_class::SERVICE_ACCOUNT_TOKEN_PATH}"
  end

  let(:generate_id_token_uri) do
    "#{described_class::IAM_CREDENTIALS_BASE_URL}/projects/-/serviceAccounts/#{sa_email}:generateIdToken"
  end

  def generate_jwt(exp:)
    JWT.encode({ exp: exp, aud: audience }, 'secret', 'HS256')
  end

  def stub_metadata_and_iam(id_token_response: id_token, iam_status: 200)
    stub_request(:get, email_uri)
      .with(headers: { described_class::METADATA_FLAVOR_HEADER => described_class::METADATA_FLAVOR_VALUE })
      .to_return(status: 200, body: sa_email)

    stub_request(:get, token_uri)
      .with(headers: { described_class::METADATA_FLAVOR_HEADER => described_class::METADATA_FLAVOR_VALUE })
      .to_return(status: 200, body: { access_token: access_token }.to_json)

    stub_request(:post, generate_id_token_uri)
      .to_return(status: iam_status, body: { token: id_token_response }.to_json)
  end

  describe '#token' do
    context 'when all requests succeed' do
      before do
        stub_metadata_and_iam
      end

      it 'mints an OIDC token via the IAM Credentials API' do
        expect(token_source.token).to eq(id_token)
      end

      it 'sends generateIdToken with the correct auth header and body' do
        token_source.token

        expect(a_request(:post, generate_id_token_uri).with(
          headers: { 'Authorization' => "Bearer #{access_token}" },
          body: {
            audience: audience,
            includeEmail: true,
            organizationNumberIncluded: true
          }.to_json
        )).to have_been_made.once
      end

      it 'caches the token and does not mint again while valid' do
        2.times { token_source.token }

        expect(a_request(:post, generate_id_token_uri)).to have_been_made.once
      end
    end

    context 'when the token has expired' do
      let(:expired_token) { generate_jwt(exp: 1.hour.ago.to_i) }

      before do
        stub_metadata_and_iam(id_token_response: expired_token)
      end

      it 're-mints on the next call' do
        2.times { token_source.token }

        expect(a_request(:post, generate_id_token_uri)).to have_been_made.twice
      end
    end

    context 'when the IAM Credentials API returns an error' do
      before do
        stub_metadata_and_iam(iam_status: 403)
      end

      it 'returns nil and logs an error' do
        expect(Gitlab::AppLogger).to receive(:error)
          .with(hash_including('message' => 'BillingEvents: generateIdToken request failed'))

        expect(token_source.token).to be_nil
      end
    end

    context 'when the metadata token response is missing the access_token key' do
      before do
        stub_request(:get, email_uri)
          .with(headers: { described_class::METADATA_FLAVOR_HEADER => described_class::METADATA_FLAVOR_VALUE })
          .to_return(status: 200, body: sa_email)
        stub_request(:get, token_uri)
          .with(headers: { described_class::METADATA_FLAVOR_HEADER => described_class::METADATA_FLAVOR_VALUE })
          .to_return(status: 200, body: {}.to_json)
        stub_request(:post, generate_id_token_uri).to_return(status: 403, body: '')
      end

      it 'sends an empty bearer token and returns nil via the request-failed path' do
        expect(Gitlab::AppLogger).to receive(:error)
          .with(hash_including('message' => 'BillingEvents: generateIdToken request failed'))

        expect(token_source.token).to be_nil

        expect(a_request(:post, generate_id_token_uri)
          .with(headers: { 'Authorization' => 'Bearer' })).to have_been_made.once
      end
    end

    context 'when the minted token has no exp claim' do
      let(:token_without_exp) { JWT.encode({ aud: audience }, 'secret', 'HS256') }

      before do
        stub_metadata_and_iam(id_token_response: token_without_exp)
      end

      it 'tracks the exception and returns nil rather than caching an always-expired token' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
        expect(Gitlab::AppLogger).to receive(:error)
          .with(hash_including('message' => 'BillingEvents: failed to mint OIDC token'))

        expect(token_source.token).to be_nil
      end
    end

    context 'when the metadata server is unreachable' do
      before do
        stub_request(:get, email_uri).to_raise(Errno::ECONNREFUSED)
      end

      it 'tracks the exception and returns nil' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
        expect(Gitlab::AppLogger).to receive(:error)
          .with(hash_including('message' => 'BillingEvents: failed to mint OIDC token'))

        expect(token_source.token).to be_nil
      end
    end
  end
end
