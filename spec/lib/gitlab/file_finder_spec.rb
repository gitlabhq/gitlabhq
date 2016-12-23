require 'spec_helper'

describe Gitlab::FileFinder do
  let(:project) { create :project }
  let(:finder) { described_class.new(project, 'master') }

  it 'finds files by name' do
    result = finder.find('CHANGELOG').first

    expect(result).to match_array(['CHANGELOG', nil])
  end

  it 'finds files by content' do
    filename, blob = finder.find('CHANGELOG').last

    expect(filename).to eq('CONTRIBUTING.md')
    expect(blob.filename).to eq('CONTRIBUTING.md')
    expect(blob.startline).to be_a(Integer)
    expect(blob.data).to include('CHANGELOG')
  end
end
