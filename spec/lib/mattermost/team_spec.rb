require 'spec_helper'

describe Mattermost::Team do
  describe '.team_admin' do
    let(:session) { double("session") }

    let(:response) do
      [{
        "id"=>"xiyro8huptfhdndadpz8r3wnbo",
        "create_at"=>1482174222155,
        "update_at"=>1482174222155,
        "delete_at"=>0,
        "display_name"=>"chatops",
        "name"=>"chatops",
        "email"=>"admin@example.com",
        "type"=>"O",
        "company_name"=>"",
        "allowed_domains"=>"",
        "invite_id"=>"o4utakb9jtb7imctdfzbf9r5ro",
        "allow_open_invite"=>false}]
    end

    let(:json) { nil }

    before do
      allow(session).to receive(:get).with('/api/v3/teams/all').
        and_return(json)
      allow(json).to receive(:parsed_response).and_return(response)
    end

    it 'gets the teams' do
      expect(described_class.all(session).count).to be(1)
    end

    it 'filters on being team admin' do
      ids = described_class.all(session).map { |team| team['id'] }

      expect(ids).to include("xiyro8huptfhdndadpz8r3wnbo")
    end
  end
end
