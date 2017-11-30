require 'spec_helper'

describe Gitlab::Auth::RequestAuthenticator do
  let(:env) do
    {
      'rack.input' => '',
      'REQUEST_METHOD' => 'GET'
    }
  end
  let(:request) { ActionDispatch::Request.new(env) }

  subject { described_class.new(request) }

  describe '#user' do
    let!(:sessionless_user) { build(:user) }
    let!(:session_user) { build(:user) }

    it 'returns sessionless user first' do
      allow_any_instance_of(described_class).to receive(:find_sessionless_user).and_return(sessionless_user)
      allow_any_instance_of(described_class).to receive(:find_user_from_warden).and_return(session_user)

      expect(subject.user).to eq sessionless_user
    end

    it 'returns session user if no sessionless user found' do
      allow_any_instance_of(described_class).to receive(:find_user_from_warden).and_return(session_user)

      expect(subject.user).to eq session_user
    end

    it 'returns nil if no user found' do
      expect(subject.user).to be_blank
    end

    it 'bubbles up exceptions' do
      allow_any_instance_of(described_class).to receive(:find_user_from_warden).and_raise(Gitlab::Auth::UnauthorizedError)
    end
  end

  describe '#find_sessionless_user' do
    let!(:access_token_user) { build(:user) }
    let!(:rss_token_user) { build(:user) }

    it 'returns access_token user first' do
      allow_any_instance_of(described_class).to receive(:find_user_from_access_token).and_return(access_token_user)
      allow_any_instance_of(described_class).to receive(:find_user_from_rss_token).and_return(rss_token_user)

      expect(subject.find_sessionless_user).to eq access_token_user
    end

    it 'returns rss_token user if no access_token user found' do
      allow_any_instance_of(described_class).to receive(:find_user_from_rss_token).and_return(rss_token_user)

      expect(subject.find_sessionless_user).to eq rss_token_user
    end

    it 'returns nil if no user found' do
      expect(subject.find_sessionless_user).to be_blank
    end

    it 'rescue Gitlab::Auth::AuthenticationError exceptions' do
      allow_any_instance_of(described_class).to receive(:find_user_from_access_token).and_raise(Gitlab::Auth::UnauthorizedError)

      expect(subject.find_sessionless_user).to be_blank
    end
  end
end
