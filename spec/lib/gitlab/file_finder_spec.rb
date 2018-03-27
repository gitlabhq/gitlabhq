require 'spec_helper'

describe Gitlab::FileFinder do
  describe '#find' do
    let(:project) { create(:project, :public, :repository) }
    let(:finder) { described_class.new(project, project.default_branch) }

    it 'finds by name' do
      results = finder.find('files')

      filename,  blob = results.find { |_, blob| blob.filename == 'files/images/wm.svg' }
      expect(filename).to eq('files/images/wm.svg')
      expect(blob).to be_a(Gitlab::SearchResults::FoundBlob)
      expect(blob.ref).to eq(finder.ref)
      expect(blob.data).not_to be_empty
    end

    it 'finds by content' do
      results = finder.find('files')

      filename, blob = results.find { |_, blob| blob.filename == 'CHANGELOG' }

      expect(filename).to eq('CHANGELOG')
      expect(blob).to be_a(Gitlab::SearchResults::FoundBlob)
      expect(blob.ref).to eq(finder.ref)
      expect(blob.data).not_to be_empty
    end
  end
end
