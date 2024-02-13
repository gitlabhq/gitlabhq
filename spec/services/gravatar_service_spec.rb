# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GravatarService, feature_category: :user_profile do
  describe '#execute' do
    let(:url) { 'http://example.com/avatar?hash=%{hash}&size=%{size}&email=%{email}&username=%{username}' }

    before do
      allow(Gitlab.config.gravatar).to receive(:plain_url).and_return(url)
    end

    it 'replaces the placeholders' do
      avatar_url = described_class.new.execute('user@example.com', 100, 2, username: 'user')

      expect(avatar_url).to include("hash=#{Digest::SHA256.hexdigest('user@example.com')}")
      expect(avatar_url).to include("size=200")
      expect(avatar_url).to include("email=user%40example.com")
      expect(avatar_url).to include("username=user")
    end
  end
end
