require 'spec_helper'

describe Mattermost::Command do
  let(:hash) { { 'token' => 'token' } }
  let(:user) { create(:user) }

  before do
    Mattermost::Session.base_uri("http://mattermost.example.com")
  end

  describe '#create' do
    it 'creates a command' do
      described_class.new(user).
        create(team_id: 'abc', url: 'http://trigger.com')
    end
  end
end
