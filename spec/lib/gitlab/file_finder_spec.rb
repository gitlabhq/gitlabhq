require 'spec_helper'

<<<<<<< HEAD
describe Gitlab::FileFinder do
  let(:project) { create :project }
  let(:finder) { described_class.new(project, 'master') }

  it 'finds files by name' do
    filename, blob = finder.find('CHANGELOG').first

    expect(filename).to eq('CHANGELOG')
    expect(blob.ref).to eq('master')
  end

  it 'finds files by content' do
    filename, blob = finder.find('CHANGELOG').last

    expect(filename).to eq('CONTRIBUTING.md')
    expect(blob.filename).to eq('CONTRIBUTING.md')
    expect(blob.startline).to be_a(Integer)
    expect(blob.data).to include('CHANGELOG')
=======
describe Gitlab::FileFinder, lib: true do
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
>>>>>>> upstream/master
  end
end
