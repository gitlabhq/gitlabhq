require 'spec_helper'

describe Mattermost::Command do
  let(:session) { double("session") }

  describe '.create' do
    it 'gets the teams' do
      allow(session).to receive(:post).and_return('token' => 'token')
      expect(session).to receive(:post)

      described_class.create(session, 'abc', url: 'http://trigger.com')
    end
  end
end
