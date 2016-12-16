require 'spec_helper'

describe Mattermost::Team do
  describe '.team_admin' do
    let(:init_load) do
      JSON.parse(File.read(Rails.root.join('spec/fixtures/', 'mattermost_initial_load.json')))
    end

    before do
      allow(described_class).to receive(:initial_load).and_return(init_load)
    end

    it 'gets the teams' do
      expect(described_class.team_admin.count).to be(2)
    end

    it 'filters on being team admin' do
      ids = described_class.team_admin.map { |team| team['id'] }
      expect(ids).to include("w59qt5a817f69jkxdz6xe7y4ir", "my9oujxf5jy1zqdgu9rihd66do")
    end
  end
end
