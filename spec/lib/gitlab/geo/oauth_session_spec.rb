require 'spec_helper'

describe Gitlab::Geo::OauthSession do
  subject { described_class.new }
  let(:oauth_app) { FactoryGirl.create(:doorkeeper_application) }
  let(:oauth_return_to) { 'http://localhost:3000/oath/geo/callback' }
  let(:dummy_state) { 'salt:hmac:return_to' }
  let(:valid_state) { described_class.new(return_to: oauth_return_to).generate_oauth_state }
  let(:access_token) { FactoryGirl.create(:doorkeeper_access_token).token }
  let(:user) { FactoryGirl.build(:user) }

  before(:each) do
    allow(subject).to receive(:oauth_app) { oauth_app }
    allow(subject).to receive(:primary_node_url) { 'http://localhost:3001/' }
  end

  describe '#is_oauth_state_valid?' do
    it 'returns false when state is not present' do
      expect(subject.is_oauth_state_valid?).to be_falsey
    end

    it 'returns false when return_to cannot be retrieved' do
      subject.state = 'invalidstate'
      expect(subject.is_oauth_state_valid?).to be_falsey
    end

    it 'returns false when hmac does not match' do
      subject.state = dummy_state
      expect(subject.is_oauth_state_valid?).to be_falsey
    end

    it 'returns true when hmac matches generated one' do
      subject.state = valid_state
      expect(subject.is_oauth_state_valid?).to be_truthy
    end
  end

  describe '#generate_oauth_state' do
    it 'returns nil when return_to is not present' do
      state = subject.generate_oauth_state
      expect(state).to be_nil
    end

    context 'when return_to is present' do
      it 'returns a string' do
        expect(valid_state).to be_a String
        expect(valid_state).not_to be_empty
      end

      it 'includes return_to value' do
        expect(valid_state).to include(oauth_return_to)
      end
    end
  end

  describe '#get_oauth_state_return_to' do
    subject { described_class.new(state: valid_state) }

    it 'returns return_to value' do
      expect(subject.get_oauth_state_return_to).to eq(oauth_return_to)
    end
  end

  describe '#authorized_url' do
    subject { described_class.new(return_to: oauth_return_to) }

    it 'returns a valid url' do
      expect(subject.authorize_url).to be_a String
      expect(subject.authorize_url).to include('http://localhost:3001/')
    end
  end

  describe '#authenticate_with_gitlab' do
    let(:response) { double }
    before(:each) { allow_any_instance_of(OAuth2::AccessToken).to receive(:get) { response } }

    context 'on success' do
      it 'returns hashed user data' do
        allow(response).to receive(:status) { 200 }
        allow(response).to receive(:parsed) { user.to_json }

        subject.authenticate_with_gitlab(access_token)
      end
    end

    context 'on invalid token' do
      it 'raises exception' do
        allow(response).to receive(:status) { 401 }

        expect { subject.authenticate_with_gitlab(access_token) }.to raise_error
      end
    end
  end
end
