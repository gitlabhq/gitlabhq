require 'spec_helper'

describe Mattermost::Team do
  let(:session) { Mattermost::Session.new('http://localhost:8065/', nil) }

  describe '.all' do
    let(:result)  { {id: 'abc', display_name: 'team'} }
    before do
      WebMock.stub_request(:get, 'http://localhost:8065/api/v3/teams/all').
        and_return({ abc: result }.to_json)
    end

    xit 'gets the teams' do
      allow(session).to receive(:with_session) { yield }

      expect(described_class.all).to eq(result)
    end
  end
end
