require 'spec_helper'

describe Mattermost::Command do
  let(:params) { { 'token' => 'token', team_id: 'abc' } }
  let(:user) { build(:user) }

  before do
    Mattermost::Session.base_uri("http://mattermost.example.com")
  end

  subject { described_class.new(user) }

  describe '#create' do
    it 'interpolates the team id' do
      allow(subject).to receive(:json_post).
        with('/api/v3/teams/abc/commands/create', body: params.to_json).
        and_return('token' => 'token')

      subject.create(params)
    end
  end
end
