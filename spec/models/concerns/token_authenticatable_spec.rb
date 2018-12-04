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
  it_behaves_like 'TokenAuthenticatable'

  describe 'generating new token' do
    context 'token is not generated yet' do
      describe 'token field accessor' do
        subject { described_class.new.send(token_field) }
        it { is_expected.not_to be_blank }
      end

      describe 'ensured token' do
        subject { described_class.new.send("ensure_#{token_field}") }

        it { is_expected.to be_a String }
        it { is_expected.not_to be_blank }
      end

      describe 'ensured! token' do
        subject { described_class.new.send("ensure_#{token_field}!") }

        it 'persists new token' do
          expect(subject).to eq described_class.current[token_field]
        end
      end
    end

    context 'token is generated' do
      before do
        subject.send("reset_#{token_field}!")
      end

      it 'persists a new token' do
        expect(subject.send(:read_attribute, token_field)).to be_a String
      end
    end
  end

  describe 'setting new token' do
    subject { described_class.new.send("set_#{token_field}", '0123456789') }

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
  let(:personal_access_token_name) { 'test-pat-01' }
  let(:token_value) { 'token' }
  let(:user) { create(:user) }
  let(:personal_access_token) do
    described_class.new(name: personal_access_token_name,
                        user_id: user.id,
                        scopes: [:api],
                        token: token,
                        token_digest: token_digest)
  end

  before do
    allow(Devise).to receive(:friendly_token).and_return(token_value)
  end

  describe '.find_by_token' do
    subject { PersonalAccessToken.find_by_token(token_value) }

    before do
      personal_access_token.save
    end

    context 'token_digest already exists' do
      let(:token) { nil }
      let(:token_digest) { Gitlab::CryptoHelper.sha256(token_value) }

      it 'finds the token' do
        expect(subject).not_to be_nil
        expect(subject.name).to eql(personal_access_token_name)
      end
    end

    context 'token_digest does not exist' do
      let(:token) { token_value }
      let(:token_digest) { nil }

      it 'finds the token' do
        expect(subject).not_to be_nil
        expect(subject.name).to eql(personal_access_token_name)
      end
    end
  end

  describe '#set_token'   do
    let(:new_token_value) { 'new-token' }
    subject { personal_access_token.set_token(new_token_value) }

    context 'token_digest already exists' do
      let(:token) { nil }
      let(:token_digest) { Gitlab::CryptoHelper.sha256(token_value) }

      it 'overwrites token_digest' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(new_token_value)
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(new_token_value))
      end
    end

    context 'token_digest does not exist but token does' do
      let(:token) { token_value }
      let(:token_digest) { nil }

      it 'creates new token_digest and clears token' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(new_token_value)
        expect(personal_access_token.token_digest).to eql(Gitlab::CryptoHelper.sha256(new_token_value))
      end
    end

    context 'token_digest does not exist, nor token' do
      let(:token) { nil }
      let(:token_digest) { nil }

      it 'creates new token_digest' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(new_token_value)
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(new_token_value))
      end
    end
  end

  describe '#ensure_token' do
    subject { personal_access_token.ensure_token }

    context 'token_digest already exists' do
      let(:token) { nil }
      let(:token_digest) { Gitlab::CryptoHelper.sha256(token_value) }

      it 'does not change token fields' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to be_nil
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(token_value))
      end
    end

    context 'token_digest does not exist but token does' do
      let(:token) { token_value }
      let(:token_digest) { nil }

      it 'does not change token fields' do
        subject

        expect(personal_access_token.read_attribute('token')).to eql(token_value)
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to be_nil
      end
    end

    context 'token_digest does not exist, nor token' do
      let(:token) { nil }
      let(:token_digest) { nil }

      it 'creates token_digest' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(token_value))
      end
    end
  end

  describe '#ensure_token!' do
    subject { personal_access_token.ensure_token! }

    context 'token_digest already exists' do
      let(:token) { nil }
      let(:token_digest) { Gitlab::CryptoHelper.sha256(token_value) }

      it 'does not change token fields' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to be_nil
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(token_value))
      end
    end

    context 'token_digest does not exist but token does' do
      let(:token) { token_value }
      let(:token_digest) { nil }

      it 'does not change token fields' do
        subject

        expect(personal_access_token.read_attribute('token')).to eql(token_value)
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to be_nil
      end
    end

    context 'token_digest does not exist, nor token' do
      let(:token) { nil }
      let(:token_digest) { nil }

      it 'creates token_digest' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(token_value))
      end
    end
  end

  describe '#reset_token!' do
    subject { personal_access_token.reset_token! }

    context 'token_digest already exists' do
      let(:token) { nil }
      let(:token_digest) { Gitlab::CryptoHelper.sha256('old-token') }

      it 'creates new token_digest' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(token_value))
      end
    end

    context 'token_digest does not exist but token does' do
      let(:token) { 'old-token' }
      let(:token_digest) { nil }

      it 'creates new token_digest and clears token' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to eql(Gitlab::CryptoHelper.sha256(token_value))
      end
    end

    context 'token_digest does not exist, nor token' do
      let(:token) { nil }
      let(:token_digest) { nil }

      it 'creates new token_digest' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(token_value))
      end
    end

    context 'token_digest exists and newly generated token would be the same' do
      let(:token) { nil }
      let(:token_digest) { Gitlab::CryptoHelper.sha256('old-token') }

      before do
        personal_access_token.save
        allow(Devise).to receive(:friendly_token).and_return(
          'old-token', token_value, 'boom!')
      end

      it 'regenerates a new token_digest' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(token_value))
      end
    end

    context 'token exists and newly generated token would be the same' do
      let(:token) { 'old-token' }
      let(:token_digest) { nil }

      before do
        personal_access_token.save
        allow(Devise).to receive(:friendly_token).and_return(
          'old-token', token_value, 'boom!')
      end

      it 'regenerates a new token_digest' do
        subject

        expect(personal_access_token.read_attribute('token')).to be_nil
        expect(personal_access_token.token).to eql(token_value)
        expect(personal_access_token.token_digest).to eql( Gitlab::CryptoHelper.sha256(token_value))
      end
    end
  end
end
