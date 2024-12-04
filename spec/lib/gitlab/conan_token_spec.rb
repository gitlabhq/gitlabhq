# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::ConanToken, :aggregate_failures, feature_category: :package_registry do
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

  def build_encoded_jwt(access_token_id:, user_id:, expire_time: nil)
    JSONWebToken::HMACToken.new(jwt_secret).tap do |jwt|
      jwt['access_token'] = access_token_id
      jwt['user_id'] = user_id || user_id
      jwt.expire_time = expire_time ||
        (jwt.issued_at + ::Gitlab::ConanToken::MAX_CONAN_TOKEN_EXPIRE_TIME).at_beginning_of_day
    end.encoded
  end

  describe '.from_personal_access_token', :freeze_time do
    let_it_be(:personal_access_token) { build(:personal_access_token) }
    let(:access_token_id) { SecureRandom.uuid }

    subject(:conan_token) { described_class.from_personal_access_token(access_token_id, personal_access_token) }

    it 'sets access token and expiry time' do
      expect(conan_token.access_token_id).to eq(access_token_id)
      expect(conan_token.expire_at).to eq(personal_access_token.expires_at)
    end

    context 'when the expiration time is nil' do
      let_it_be(:personal_access_token) { build(:personal_access_token, expires_at: nil) }

      it 'sets default time' do
        expect(conan_token.expire_at).to eq(Time.zone.now + described_class::MAX_CONAN_TOKEN_EXPIRE_TIME)
      end
    end

    context 'when the token is not active' do
      let_it_be(:expiration_time) { 1.day.ago }
      let_it_be(:personal_access_token) { build(:personal_access_token, expires_at: expiration_time) }

      it 'does not set the access token' do
        expect(conan_token).to be_nil
      end
    end
  end

  describe '.from_job' do
    let_it_be(:stubbed_user) { build_stubbed(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:job) { create(:ci_build, :with_token, :running, project: project, user: stubbed_user) }

    subject(:conan_token) { described_class.from_job(job) }

    it 'sets access token id and user id', :freeze_time do
      expect(conan_token.user_id).to eq(stubbed_user.id)
      expect(conan_token.expire_at).to eq(Time.zone.now + project.build_timeout)
    end

    context 'when the job is not running' do
      let_it_be(:job) { create(:ci_build, :with_token, :success, project: project, user: stubbed_user) }

      it { is_expected.to be_nil }
    end

    context 'when the job is nil' do
      let(:job) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '.from_deploy_token', :freeze_time do
    let(:expiration_time) { 30.days.from_now.beginning_of_day }
    let(:deploy_token) { build(:deploy_token, username: 'test_user', expires_at: expiration_time) }

    subject(:conan_token) { described_class.from_deploy_token(deploy_token) }

    before do
      allow(deploy_token).to receive(:token).and_return('test_token')
    end

    it 'creates a conan token from a deploy token' do
      expect(conan_token).to be_a(described_class)
      expect(conan_token.access_token_id).to eq('test_token')
      expect(conan_token.user_id).to eq('test_user')
      expect(conan_token.expire_at).to eq(expiration_time)
    end

    context 'when the expiration time is too long' do
      let(:expiration_time) { 100.days.from_now.beginning_of_day }

      it 'updates time to the maximum expiration time' do
        expect(conan_token.expire_at).to eq(Time.zone.now + described_class::MAX_CONAN_TOKEN_EXPIRE_TIME)
      end
    end

    context 'when there is no expiration time' do
      let(:expiration_time) { nil }

      it 'updates time to default time' do
        expect(conan_token.expire_at).to eq(Time.zone.now + described_class::MAX_CONAN_TOKEN_EXPIRE_TIME)
      end
    end
  end

  describe '.decode' do
    let(:jwt) { build_encoded_jwt(access_token_id: 123, user_id: 456) }

    subject(:conan_token) { described_class.decode(jwt) }

    it 'sets access token id and user id' do
      expect(conan_token.access_token_id).to eq(123)
      expect(conan_token.user_id).to eq(456)
    end

    context 'when given an invalid JWT token' do
      let(:jwt) { 'invalid-jwt' }

      it { is_expected.to be_nil }
    end

    context 'when given an expired JWT token' do
      let(:jwt) { build_encoded_jwt(access_token_id: 123, user_id: 456, expire_time: 1.day.ago) }

      it { is_expected.to be_nil }
    end
  end

  describe '#to_jwt' do
    let(:jwt) do
      build_encoded_jwt(
        access_token_id: 123,
        user_id: 456,
        expire_time: Time.zone.now + ::Gitlab::ConanToken::MAX_CONAN_TOKEN_EXPIRE_TIME
      )
    end

    subject(:conan_jwt_token) { described_class.new(access_token_id: 123, user_id: 456).to_jwt }

    it 'returns the encoded JWT' do
      allow(SecureRandom).to receive(:uuid).and_return('u-u-i-d')
      expect(conan_jwt_token).to eq(jwt)
    end

    context 'when creating with an expiry time' do
      let(:expiration_time) { 30.days.from_now }
      let(:jwt) { build_encoded_jwt(access_token_id: 123, user_id: 456, expire_time: expiration_time) }

      subject(:conan_jwt_token) do
        described_class.new(access_token_id: 123, user_id: 456, expire_at: expiration_time).to_jwt
      end

      it 'returns the encoded JWT with the expiry time' do
        allow(SecureRandom).to receive(:uuid).and_return('u-u-i-d')
        expect(conan_jwt_token).to eq(jwt)
      end
    end
  end
end
