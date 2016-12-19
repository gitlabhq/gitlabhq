require 'spec_helper'

describe Mattermost::Team do
  describe '.team_admin' do
    let(:session) { double("session") }
    # TODO fix fixture
    let(:json) { File.read(Rails.root.join('spec/fixtures/', 'mattermost_initial_load.json')) } 
    let(:parsed_response) { JSON.parse(json) }

    before do
      allow(session).to receive(:get).with('/api/v3/teams/all').
        and_return(json)
      allow(json).to receive(:parsed_response).and_return(parsed_response)
    end

    xit 'gets the teams' do
      expect(described_class.all(session).count).to be(2)
    end

    xit 'filters on being team admin' do
      expect(ids).to include("w59qt5a817f69jkxdz6xe7y4ir", "my9oujxf5jy1zqdgu9rihd66do")
    end
  end
end
