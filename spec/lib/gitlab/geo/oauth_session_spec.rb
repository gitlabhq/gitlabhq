require 'spec_helper'

describe Gitlab::Geo::OauthSession do
  subject { described_class.new }
  let(:oauth_app) { FactoryGirl.create(:doorkeeper_application) }
  let(:oauth_return_to) { 'http://localhost:3000/oath/geo/callback' }
  let(:dummy_state) { 'salt:hmac:return_to' }
  let(:valid_state) { described_class.new(return_to: oauth_return_to).generate_oauth_state }

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
    before(:each) do
      allow(subject).to receive(:oauth_app) { oauth_app }
      allow(subject).to receive(:primary_node_url) { 'http://localhost:3001/' }
    end

    it 'returns a valid url' do
      expect(subject.authorize_url).to be_a String
      expect(subject.authorize_url).to include('http://localhost:3001/')
    end
  end
end
