# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatable, feature_category: :shared do
  describe '.token_authenticatable_sensitive_fields' do
    let(:base_class) do
      Class.new do
        include TokenAuthenticatable

        attr_accessor :name, :super_secret
      end
    end

    let(:test_class) do
      Class.new(base_class) do
        add_authentication_token_field :super_secret
      end
    end

    subject(:token_authenticatable_fields) { test_class.token_authenticatable_sensitive_fields }

    it { is_expected.to contain_exactly(:super_secret) }

    context 'with encrypted: true' do
      let(:test_class) do
        Class.new(base_class) do
          attr_accessor :name, :super_secret

          add_authentication_token_field :super_secret, encrypted: true
        end
      end

      it { is_expected.to contain_exactly(:super_secret, :super_secret_encrypted) }
    end

    context 'with digest: true' do
      let(:test_class) do
        Class.new(base_class) do
          attr_accessor :name, :super_secret

          add_authentication_token_field :super_secret, digest: true
        end
      end

      it { is_expected.to contain_exactly(:super_secret, :super_secret_digest) }
    end

    context 'with expires_at option' do
      let(:test_class) do
        Class.new(base_class) do
          attr_accessor :name, :super_secret

          add_authentication_token_field :super_secret, expires_at: -> { Time.current }
        end
      end

      it { is_expected.to contain_exactly(:super_secret) }
    end
  end
end

RSpec.shared_examples 'TokenAuthenticatable' do
  describe 'dynamically defined methods' do
    it { expect(described_class).to respond_to("find_by_#{token_field}") }
    it { is_expected.to respond_to("ensure_#{token_field}") }
    it { is_expected.to respond_to("set_#{token_field}") }
    it { is_expected.to respond_to("reset_#{token_field}!") }
  end

  describe '.token_authenticatable_fields' do
    it 'includes the token field' do
      expect(described_class.token_authenticatable_fields).to include(token_field)
    end
  end
end

RSpec.describe User, 'TokenAuthenticatable' do
  let(:token_field) { :feed_token }

  it_behaves_like 'TokenAuthenticatable'

  describe 'ensures authentication token' do
    subject { create(:user).send(token_field) }

    it { is_expected.to be_a String }
  end
end

RSpec.describe ApplicationSetting, 'TokenAuthenticatable' do
  let(:token_field) { :runners_registration_token }
  let(:settings) { described_class.new }

  it_behaves_like 'TokenAuthenticatable'

  describe 'generating new token' do
    context 'token is not generated yet' do
      describe 'token field accessor' do
        subject { settings.send(token_field) }

        it { is_expected.not_to be_blank }
      end

      describe "ensure_runners_registration_token" do
        subject { settings.send("ensure_#{token_field}") }

        it { is_expected.to be_a String }
        it { is_expected.not_to be_blank }

        it 'does not persist token' do
          expect(settings).not_to be_persisted
        end
      end

      describe 'ensure_runners_registration_token!' do
        subject { settings.send("ensure_#{token_field}!") }

        it 'persists new token as an encrypted string' do
          expect(subject).to eq settings.reload.runners_registration_token
          expect(settings.read_attribute('runners_registration_token_encrypted'))
            .to eq TokenAuthenticatableStrategies::EncryptionHelper.encrypt_token(subject)
          expect(settings).to be_persisted
        end

        it 'does not persist token in a clear text' do
          expect(subject).not_to eq settings.reload
            .read_attribute('runners_registration_token_encrypted')
        end
      end
    end

    context 'token is generated' do
      before do
        settings.send("reset_#{token_field}!")
      end

      it 'persists a new token' do
        expect(settings.runners_registration_token).to be_a String
      end
    end
  end

  describe 'setting new token' do
    subject { settings.send("set_#{token_field}", '0123456789') }

    it { is_expected.to eq '0123456789' }
  end

  describe 'multiple token fields' do
    before_all do
      described_class.send(:add_authentication_token_field, :yet_another_token)
    end

    it { is_expected.to respond_to(:ensure_runners_registration_token) }
    it { is_expected.to respond_to(:ensure_error_tracking_access_token) }
    it { is_expected.to respond_to(:ensure_yet_another_token) }
  end

  describe 'setting same token field multiple times' do
    subject { described_class.send(:add_authentication_token_field, :runners_registration_token) }

    it 'raises error' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end

RSpec.describe PersonalAccessToken, 'TokenAuthenticatable' do
  shared_examples 'changes personal access token' do
    it 'sets new token' do
      subject

      expect(personal_access_token.token).to eq("#{described_class.token_prefix}#{token_value}")
      expect(personal_access_token.token_digest).to eq(Gitlab::CryptoHelper.sha256("#{described_class.token_prefix}#{token_value}"))
    end
  end

  shared_examples 'does not change personal access token' do
    it 'sets new token' do
      subject

      expect(personal_access_token.token).to be(nil)
      expect(personal_access_token.token_digest).to eq(token_digest)
    end
  end

  let(:token_value) { Devise.friendly_token }
  let(:token_digest) { Gitlab::CryptoHelper.sha256(token_value) }
  let(:user) { create(:user) }
  let(:personal_access_token) do
    described_class.new(name: 'test-pat-01', user_id: user.id, scopes: [:api], token_digest: token_digest, expires_at: 30.days.from_now)
  end

  before do
    allow(Devise).to receive(:friendly_token).and_return(token_value)
  end

  describe '.find_by_token' do
    subject { described_class.find_by_token(token_value) }

    it 'finds the token' do
      personal_access_token.save!

      expect(subject).to eq(personal_access_token)
    end
  end

  describe '#set_token'   do
    let(:new_token_value) { 'new-token' }

    subject { personal_access_token.set_token(new_token_value) }

    it 'sets new token' do
      subject

      expect(personal_access_token.token).to eq(new_token_value)
      expect(personal_access_token.token_digest).to eq(Gitlab::CryptoHelper.sha256(new_token_value))
    end
  end

  describe '#ensure_token' do
    subject { personal_access_token.ensure_token }

    context 'token_digest does not exist' do
      let(:token_digest) { nil }

      it_behaves_like 'changes personal access token'
    end

    context 'token_digest already generated' do
      let(:token_digest) { 's3cr3t' }

      it_behaves_like 'does not change personal access token'
    end
  end

  describe '#ensure_token!' do
    subject { personal_access_token.ensure_token! }

    context 'token_digest does not exist' do
      let(:token_digest) { nil }

      it_behaves_like 'changes personal access token'
    end

    context 'token_digest already generated' do
      let(:token_digest) { 's3cr3t' }

      it_behaves_like 'does not change personal access token'
    end
  end

  describe '#reset_token!' do
    subject { personal_access_token.reset_token! }

    context 'token_digest does not exist' do
      let(:token_digest) { nil }

      it_behaves_like 'changes personal access token'
    end

    context 'token_digest already generated' do
      let(:token_digest) { 's3cr3t' }

      it_behaves_like 'changes personal access token'
    end
  end
end

RSpec.describe Ci::Build, 'TokenAuthenticatable' do
  let(:token_field) { :token }
  let(:build) { FactoryBot.build(:ci_build, :created, ci_stage: create(:ci_stage)) }

  it_behaves_like 'TokenAuthenticatable'

  describe 'generating new token' do
    context 'token is not generated yet' do
      describe 'token field accessor' do
        it 'does not generate a token when saving a build' do
          expect { build.save! }.not_to change(build, :token).from(nil)
        end
      end

      describe "ensure_token" do
        subject { build.ensure_token }

        it { is_expected.to be_a String }
        it { is_expected.not_to be_blank }

        it 'does not persist token' do
          expect(build).not_to be_persisted
        end
      end

      describe 'ensure_token!' do
        it 'persists a new token' do
          expect(build.ensure_token!).to eq build.reload.token
          expect(build).to be_persisted
        end

        it 'persists new token as an encrypted string' do
          build.ensure_token!

          encrypted = TokenAuthenticatableStrategies::EncryptionHelper.encrypt_token(build.token)

          expect(build.read_attribute('token_encrypted')).to eq encrypted
        end

        it 'does not persist a token in a clear text' do
          build.ensure_token!

          expect(build.read_attribute('token')).to be_nil
        end
      end
    end

    describe '#reset_token!' do
      it 'persists a new token' do
        build.save!

        build.token.then do |previous_token|
          build.reset_token!

          expect(build.token).not_to eq previous_token
          expect(build.token).to be_a String
        end
      end
    end
  end

  describe 'setting a new token' do
    subject { build.set_token('0123456789') }

    it 'returns the token' do
      expect(subject).to eq '0123456789'
    end

    it 'writes a new encrypted token' do
      expect(build.read_attribute('token_encrypted')).to be_nil
      expect(subject).to eq '0123456789'
      expect(build.read_attribute('token_encrypted')).to be_present
    end

    it 'does not write a new cleartext token' do
      expect(build.read_attribute('token')).to be_nil
      expect(subject).to eq '0123456789'
      expect(build.read_attribute('token')).to be_nil
    end
  end

  describe '#token_with_expiration' do
    describe '#expirable?' do
      subject { build.token_with_expiration.expirable? }

      it { is_expected.to eq(false) }
    end
  end
end

RSpec.describe Ci::Runner, 'TokenAuthenticatable', :freeze_time do
  let_it_be(:non_expirable_runner) { create(:ci_runner) }
  let_it_be(:non_expired_runner) { create(:ci_runner).tap { |r| r.update!(token_expires_at: 5.seconds.from_now) } }
  let_it_be(:expired_runner) { create(:ci_runner).tap { |r| r.update!(token_expires_at: 5.seconds.ago) } }

  describe '#token_expired?' do
    subject { runner.token_expired? }

    context 'when runner has no token expiration' do
      let(:runner) { non_expirable_runner }

      it { is_expected.to eq(false) }
    end

    context 'when runner token is not expired' do
      let(:runner) { non_expired_runner }

      it { is_expected.to eq(false) }
    end

    context 'when runner token is expired' do
      let(:runner) { expired_runner }

      it { is_expected.to eq(true) }
    end
  end

  describe '#token_with_expiration' do
    describe '#token' do
      subject { non_expired_runner.token_with_expiration.token }

      it { is_expected.to eq(non_expired_runner.token) }
    end

    describe '#token_expires_at' do
      subject { non_expired_runner.token_with_expiration.token_expires_at }

      it { is_expected.to eq(non_expired_runner.token_expires_at) }
    end

    describe '#expirable?' do
      subject { non_expired_runner.token_with_expiration.expirable? }

      it { is_expected.to eq(true) }
    end
  end

  describe '.find_by_token' do
    subject { described_class.find_by_token(runner.token) }

    context 'when runner has no token expiration' do
      let(:runner) { non_expirable_runner }

      it { is_expected.to eq(non_expirable_runner) }
    end

    context 'when runner token is not expired' do
      let(:runner) { non_expired_runner }

      it { is_expected.to eq(non_expired_runner) }
    end

    context 'when runner token is expired' do
      let(:runner) { expired_runner }

      it { is_expected.to be_nil }
    end
  end
end

RSpec.shared_examples 'prefixed token rotation' do
  describe "ensure_runners_token" do
    subject { instance.ensure_runners_token }

    context 'token is not set' do
      it 'generates a new token' do
        expect(subject).to match(/^#{RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX}/o)
        expect(instance).not_to be_persisted
      end
    end

    context 'token is set, but does not match the prefix' do
      before do
        instance.set_runners_token('abcdef')
      end

      it 'generates a new token' do
        expect(subject).to match(/^#{RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX}/o)
        expect(instance).not_to be_persisted
      end
    end

    context 'token is set and matches prefix' do
      before do
        instance.set_runners_token(RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX + '-abcdef')
      end

      it 'leaves the token unchanged' do
        expect { subject }.not_to change(instance, :runners_token)
        expect(instance).not_to be_persisted
      end
    end
  end

  describe 'ensure_runners_token!' do
    subject { instance.ensure_runners_token! }

    context 'token is not set' do
      it 'generates a new token' do
        expect(subject).to match(/^#{RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX}/o)
        expect(instance).to be_persisted
      end
    end

    context 'token is set, but does not match the prefix' do
      before do
        instance.set_runners_token('abcdef')
      end

      it 'generates a new token' do
        expect(subject).to match(/^#{RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX}/o)
        expect(instance).to be_persisted
      end
    end

    context 'token is set and matches prefix' do
      before do
        instance.set_runners_token(RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX + '-abcdef')
        instance.save!
      end

      it 'leaves the token unchanged' do
        expect { subject }.not_to change(instance, :runners_token)
      end
    end
  end
end

RSpec.describe Project, 'TokenAuthenticatable' do
  let(:instance) { build(:project, runners_token: nil) }

  it_behaves_like 'prefixed token rotation'
end

RSpec.describe Group, 'TokenAuthenticatable' do
  let(:instance) { build(:group, runners_token: nil) }

  it_behaves_like 'prefixed token rotation'
end
