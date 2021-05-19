# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::ConanToken do
  let(:base_secret) { SecureRandom.base64(64) }

  let(:jwt_secret) do
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('SHA256'),
      base_secret,
      described_class::HMAC_KEY
    )
  end

  before do
    allow(Settings).to receive(:attr_encrypted_db_key_base).and_return(base_secret)
  end

  def build_jwt(access_token_id:, user_id:, expire_time: nil)
    JSONWebToken::HMACToken.new(jwt_secret).tap do |jwt|
      jwt['access_token'] = access_token_id
      jwt['user_id'] = user_id || user_id
      jwt.expire_time = expire_time || jwt.issued_at + ::Gitlab::ConanToken::CONAN_TOKEN_EXPIRE_TIME
    end
  end

  describe '.from_personal_access_token' do
    it 'sets access token id and user id' do
      access_token = double(id: 123, user_id: 456)

      token = described_class.from_personal_access_token(access_token)

      expect(token.access_token_id).to eq(123)
      expect(token.user_id).to eq(456)
    end
  end

  describe '.from_job' do
    it 'sets access token id and user id' do
      user = double(id: 456)
      job = double(token: 123, user: user)

      token = described_class.from_job(job)

      expect(token.access_token_id).to eq(123)
      expect(token.user_id).to eq(456)
    end
  end

  describe '.from_deploy_token' do
    it 'sets access token id and user id' do
      deploy_token = double(token: '123', username: 'bob')

      token = described_class.from_deploy_token(deploy_token)

      expect(token.access_token_id).to eq('123')
      expect(token.user_id).to eq('bob')
    end
  end

  describe '.decode' do
    it 'sets access token id and user id' do
      jwt = build_jwt(access_token_id: 123, user_id: 456)

      token = described_class.decode(jwt.encoded)

      expect(token.access_token_id).to eq(123)
      expect(token.user_id).to eq(456)
    end

    it 'returns nil for invalid JWT' do
      expect(described_class.decode('invalid-jwt')).to be_nil
    end

    it 'returns nil for expired JWT' do
      jwt = build_jwt(access_token_id: 123,
                      user_id: 456,
                      expire_time: Time.zone.now - (::Gitlab::ConanToken::CONAN_TOKEN_EXPIRE_TIME + 1.hour))

      expect(described_class.decode(jwt.encoded)).to be_nil
    end
  end

  describe '#to_jwt' do
    it 'returns the encoded JWT' do
      allow(SecureRandom).to receive(:uuid).and_return('u-u-i-d')

      freeze_time do
        jwt = build_jwt(access_token_id: 123, user_id: 456)

        token = described_class.new(access_token_id: 123, user_id: 456)

        expect(token.to_jwt).to eq(jwt.encoded)
      end
    end
  end
end
