# frozen_string_literal: true

require 'spec_helper'

shared_examples 'TokenAuthenticatable' do
  describe 'dynamically defined methods' do
    it { expect(described_class).to respond_to("find_by_#{token_field}") }
    it { is_expected.to respond_to("ensure_#{token_field}") }
    it { is_expected.to respond_to("set_#{token_field}") }
    it { is_expected.to respond_to("reset_#{token_field}!") }
  end
end

describe User, 'TokenAuthenticatable' do
  let(:token_field) { :feed_token }

  it_behaves_like 'TokenAuthenticatable'

  describe 'ensures authentication token' do
    subject { create(:user).send(token_field) }

    it { is_expected.to be_a String }
  end
end

describe ApplicationSetting, 'TokenAuthenticatable' do
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
            .to eq Gitlab::CryptoHelper.aes256_gcm_encrypt(subject)
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
    before(:all) do
      described_class.send(:add_authentication_token_field, :yet_another_token)
    end

    it { is_expected.to respond_to(:ensure_runners_registration_token) }
    it { is_expected.to respond_to(:ensure_yet_another_token) }
  end

  describe 'setting same token field multiple times' do
    subject { described_class.send(:add_authentication_token_field, :runners_registration_token) }

    it 'raises error' do
      expect {subject}.to raise_error(ArgumentError)
    end
  end
end

describe PersonalAccessToken, 'TokenAuthenticatable' do
  shared_examples 'changes personal access token' do
    it 'sets new token' do
      subject

      expect(personal_access_token.token).to eq(token_value)
      expect(personal_access_token.token_digest).to eq(Gitlab::CryptoHelper.sha256(token_value))
    end
  end

  shared_examples 'does not change personal access token' do
    it 'sets new token' do
      subject

      expect(personal_access_token.token).to be(nil)
      expect(personal_access_token.token_digest).to eq(token_digest)
    end
  end

  let(:token_value) { 'token' }
  let(:token_digest) { Gitlab::CryptoHelper.sha256(token_value) }
  let(:user) { create(:user) }
  let(:personal_access_token) do
    described_class.new(name: 'test-pat-01',
                        user_id: user.id,
                        scopes: [:api],
                        token_digest: token_digest)
  end

  before do
    allow(Devise).to receive(:friendly_token).and_return(token_value)
  end

  describe '.find_by_token' do
    subject { PersonalAccessToken.find_by_token(token_value) }

    it 'finds the token' do
      personal_access_token.save

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

describe Ci::Build, 'TokenAuthenticatable' do
  let(:token_field) { :token }
  let(:build) { FactoryBot.build(:ci_build) }

  it_behaves_like 'TokenAuthenticatable'

  describe 'generating new token' do
    context 'token is not generated yet' do
      describe 'token field accessor' do
        it 'makes it possible to access token' do
          expect(build.token).to be_nil

          build.save!

          expect(build.token).to be_present
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

          encrypted = Gitlab::CryptoHelper.aes256_gcm_encrypt(build.token)

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

        build.token.yield_self do |previous_token|
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
end
