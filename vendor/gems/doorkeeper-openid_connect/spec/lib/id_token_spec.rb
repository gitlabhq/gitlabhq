# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::IdToken do
  subject { described_class.new(access_token, nonce) }

  let(:access_token) { create :access_token, resource_owner_id: user.id, scopes: 'openid' }
  let(:user) { create :user }
  let(:nonce) { '123456' }

  before do
    allow(Time).to receive(:now) { Time.zone.at 60 }
  end

  describe '#nonce' do
    it 'returns the stored nonce' do
      expect(subject.nonce).to eq '123456'
    end
  end

  describe '#claims' do
    it 'returns all default claims' do
      expect(subject.claims).to eq(
        iss: 'dummy',
        sub: user.id.to_s,
        aud: access_token.application.uid,
        exp: 180,
        iat: 60,
        nonce: nonce,
        auth_time: 23,
        both_responses: 'both',
        id_token_response: 'id_token',
      )
    end

    context 'when application is not set on the access token' do
      before do
        access_token.application = nil
      end

      it 'returns all default claims except audience' do
        expect(subject.claims).to eq(
          iss: 'dummy',
          sub: user.id.to_s,
          aud: nil,
          exp: 180,
          iat: 60,
          nonce: nonce,
          auth_time: 23,
          both_responses: 'both',
          id_token_response: 'id_token',
        )
      end
    end
  end

  describe '#as_json' do
    it 'returns claims with nil values and empty strings removed' do
      allow(subject).to receive(:issuer).and_return(nil)
      allow(subject).to receive(:subject).and_return('')
      allow(subject).to receive(:audience).and_return(' ')

      json = subject.as_json

      expect(json).not_to include :iss
      expect(json).not_to include :sub
      expect(json).to include :aud
    end
  end

  describe '#as_jws_token' do
    shared_examples 'a jws token' do
      it 'returns claims encoded as JWT' do
        algorithms = [Doorkeeper::OpenidConnect.signing_algorithm.to_s]

        data, headers = ::JWT.decode subject.as_jws_token, Doorkeeper::OpenidConnect.signing_key.keypair, true, { algorithms: algorithms }

        expect(data.to_hash).to eq subject.as_json.stringify_keys
        expect(headers["kid"]).to eq Doorkeeper::OpenidConnect.signing_key.kid
        expect(headers["alg"]).to eq Doorkeeper::OpenidConnect.signing_algorithm.to_s
      end
    end

    it_behaves_like 'a jws token'

    context 'when signing_algorithm is EC' do
      before { configure_ec }

      it_behaves_like 'a jws token'
    end

    context 'when signing_algorithm is HMAC' do
      before { configure_hmac }

      it_behaves_like 'a jws token'
    end
  end
end
