require 'spec_helper'

describe Gitlab::FileFinder do
  describe '#find' do
    let(:project) { create(:project, :public, :repository) }
    let(:finder) { described_class.new(project, project.default_branch) }

    it 'finds by name' do
      results = finder.find('files')
      expect(results.map(&:first)).to include('files/images/wm.svg')
    end

    it 'finds by content' do
      results = finder.find('files')

      blob = results.select { |result| result.first == "CHANGELOG" }.flatten.last

      expect(blob.filename).to eq("CHANGELOG")
    end
  end
end
