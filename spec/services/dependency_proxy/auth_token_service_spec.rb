# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::AuthTokenService do
  include DependencyProxyHelpers

  describe '.decoded_token_payload' do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { build_jwt(user) }

    subject { described_class.decoded_token_payload(token.encoded) }

    it 'returns the user' do
      result = subject

      expect(result['user_id']).to eq(user.id)
      expect(result['deploy_token']).to be_nil
    end

    context 'with a deploy token' do
      let_it_be(:deploy_token) { create(:deploy_token) }
      let_it_be(:token) { build_jwt(deploy_token) }

      it 'returns the deploy token' do
        result = subject

        expect(result['deploy_token']).to eq(deploy_token.token)
        expect(result['user_id']).to be_nil
      end
    end

    it 'raises an error if the token is expired' do
      travel_to(Time.zone.now + Auth::DependencyProxyAuthenticationService.token_expire_at + 1.minute) do
        expect { subject }.to raise_error(JWT::ExpiredSignature)
      end
    end

    it 'raises an error if decoding fails' do
      allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)

      expect { subject }.to raise_error(JWT::DecodeError)
    end

    it 'raises an error if signature is immature' do
      allow(JWT).to receive(:decode).and_raise(JWT::ImmatureSignature)

      expect { subject }.to raise_error(JWT::ImmatureSignature)
    end
  end
end
