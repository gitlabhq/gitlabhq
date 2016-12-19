require 'spec_helper'

describe Mattermost::Team do
  describe '.team_admin' do
    let(:session) { double("session") }
    let(:json) { File.read(Rails.root.join('spec/fixtures/', 'mattermost_initial_load.json')) } 
    let(:parsed_response) { JSON.parse(json) }

    before do
      allow(session).to receive(:get).with('/api/v3/users/initial_load').
        and_return(json)
      allow(json).to receive(:parsed_response).and_return(parsed_response)
    end

    it 'gets the teams' do
      expect(described_class.team_admin(session).count).to be(2)
    end

    it 'filters on being team admin' do
      ids = described_class.team_admin(session).map { |team| team['id'] }

      expect(ids).to include("w59qt5a817f69jkxdz6xe7y4ir", "my9oujxf5jy1zqdgu9rihd66do")
    end
  end
end
