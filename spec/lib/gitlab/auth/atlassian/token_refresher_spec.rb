# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Atlassian::TokenRefresher, feature_category: :integrations do
  subject(:token_refresher) { described_class.new(atlassian_identity) }

  let(:atlassian_identity) { build(:atlassian_identity) }
  let(:refresh_response_headers) { { 'Content-Type' => 'application/json' } }
  let(:refresh_response_body) do
    { refresh_token: 'newrefresh', access_token: 'newaccess', expires_in: 3600 }.to_json
  end

  describe '#needs_refresh?' do
    subject(:needs_refresh?) { token_refresher.needs_refresh? }

    context 'when the token is expiring in more than 5 minutes' do
      before do
        atlassian_identity.expires_at = 6.minutes.from_now
      end

      it { is_expected.to eq(false) }
    end

    context 'when the token is expiring in less than 5 minutes' do
      before do
        atlassian_identity.expires_at = 4.minutes.from_now
      end

      it { is_expected.to eq(true) }
    end

    context 'when the token has already expired' do
      before do
        atlassian_identity.expires_at = 1.hour.ago
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#refresh!' do
    subject(:refresh!) { token_refresher.refresh! }

    context 'when the response is good' do
      before do
        stub_request(:post, described_class::REFRESH_TOKEN_URL)
          .to_return(
            status: 200,
            headers: refresh_response_headers,
            body: refresh_response_body
          )
      end

      it 'changes the identity access_token, refresh_token and expires_at' do
        expect { refresh! }
          .to change { atlassian_identity.refresh_token }.to('newrefresh')
          .and change { atlassian_identity.token }.to('newaccess')
          .and change { atlassian_identity.expires_at }.to be_within(1.minute).of(3600.seconds.from_now)
      end
    end

    context 'when the response is bad' do
      before do
        stub_request(:post, described_class::REFRESH_TOKEN_URL)
          .to_return(status: 500, headers: refresh_response_headers, body: { error: 'Broken' }.to_json)
      end

      it 'raises an exception' do
        expect { refresh! }.to raise_exception(described_class::AtlassianTokenRefreshError, 'Broken')
      end
    end
  end

  describe '#refresh_if_needed!' do
    subject(:refresh_if_needed!) { token_refresher.refresh_if_needed! }

    before do
      stub_request(:post, described_class::REFRESH_TOKEN_URL)
        .to_return(
          status: 200, headers: refresh_response_headers,
          body: refresh_response_body
        )
    end

    context 'when a refresh is needed' do
      before do
        atlassian_identity.expires_at = 1.minute.from_now
      end

      it 'refreshes the token' do
        expect { refresh_if_needed! }.to change { atlassian_identity.refresh_token }.to('newrefresh')
      end
    end

    context 'when a refresh is not needed' do
      before do
        atlassian_identity.expires_at = 10.minutes.from_now
      end

      it 'does not refresh the token' do
        expect { refresh_if_needed! }.not_to change { atlassian_identity.refresh_token }
      end
    end
  end
end
