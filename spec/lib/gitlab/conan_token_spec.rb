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
      jwt.expire_time = expire_time ||
        (jwt.issued_at + ::Gitlab::ConanToken::MAX_CONAN_TOKEN_EXPIRE_TIME).at_beginning_of_day
    end
  end

  describe '.from_personal_access_token', :freeze_time do
    let(:personal_access_token) { build(:personal_access_token) }

    let(:access_token_id) { SecureRandom.uuid }

    it 'sets access token and user id and does not use the token id' do
      token = described_class.from_personal_access_token(
        access_token_id,
        personal_access_token
      )

      expect(token.access_token_id).not_to eq(personal_access_token.id)
      expect(token.access_token_id).to eq(access_token_id)
      expect(token.expire_at).to eq(personal_access_token.expires_at)
    end

    context 'when expires is nil' do
      let(:personal_access_token) { build(:personal_access_token, expires_at: nil) }

      it 'sets default time' do
        token = described_class.from_personal_access_token(
          access_token_id,
          personal_access_token
        )
        expect(token.expire_at).to eq(Time.zone.now + described_class::MAX_CONAN_TOKEN_EXPIRE_TIME)
      end
    end

    context 'when token is not active' do
      let(:expiration_date) { 1.day.ago }
      let(:personal_access_token) { build(:personal_access_token, expires_at: expiration_date) }
      let(:user_id) { personal_access_token.user_id }

      it 'does not set access token' do
        expect(described_class.from_personal_access_token(user_id, personal_access_token)).to be_nil
      end
    end
  end

  describe '.from_job' do
    let(:stubbed_user) { build_stubbed(:user) }
    let_it_be(:project) { create(:project) }
    let(:job) { create(:ci_build, :with_token, project: project, user: stubbed_user) }

    it 'sets access token id and user id', :freeze_time do
      token = described_class.from_job(job)
      expect(job.token).to be_present
      expect(token.user_id).to eq(stubbed_user.id)
      expect(token.expire_at).to eq(Time.zone.now + project.build_timeout)
    end
  end

  describe '.from_deploy_token', :freeze_time do
    let(:expiration_date) { 30.days.from_now.beginning_of_day }
    let(:deploy_token) { build(:deploy_token, username: 'test_user', expires_at: expiration_date) }

    before do
      allow(deploy_token).to receive(:token).and_return('test_token')
    end

    it 'creates a ConanToken from a deploy token' do
      conan_token = described_class.from_deploy_token(deploy_token)

      expect(conan_token).to be_a(described_class)
      expect(conan_token.access_token_id).to eq('test_token')
      expect(conan_token.user_id).to eq('test_user')
      expect(conan_token.expire_at).to eq(expiration_date)
    end

    context 'when expiration date is too long' do
      let(:expiration_date) { 100.days.from_now.beginning_of_day }

      it 'updates dates to the maximum expire time' do
        token = described_class.from_deploy_token(deploy_token)

        expect(token.expire_at).to eq(Time.zone.now + described_class::MAX_CONAN_TOKEN_EXPIRE_TIME)
      end
    end

    context 'when no expire date is given' do
      let(:expiration_date) { nil }

      it 'updates dates to default date' do
        token = described_class.from_deploy_token(deploy_token)

        expect(token.expire_at).to eq(Time.zone.now + described_class::MAX_CONAN_TOKEN_EXPIRE_TIME)
      end
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
                      expire_time: 1.day.ago)

      expect(described_class.decode(jwt.encoded)).to be_nil
    end
  end

  describe '#to_jwt' do
    it 'returns the encoded JWT' do
      allow(SecureRandom).to receive(:uuid).and_return('u-u-i-d')
      jwt = build_jwt(access_token_id: 123,
                      user_id: 456,
                      expire_time: Time.zone.now + ::Gitlab::ConanToken::MAX_CONAN_TOKEN_EXPIRE_TIME
                     )

      token = described_class.new(access_token_id: 123, user_id: 456)

      expect(token.to_jwt).to eq(jwt.encoded)
    end

    it 'returns the encoded JWT with date' do
      allow(SecureRandom).to receive(:uuid).and_return('u-u-i-d')
      expiration_date = 30.days.from_now
      jwt = build_jwt(access_token_id: 123, user_id: 456, expire_time: expiration_date)
      token = described_class.new(access_token_id: 123, user_id: 456, expire_at: expiration_date)
      expect(token.to_jwt).to eq(jwt.encoded)
    end
  end
end
