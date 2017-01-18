require 'spec_helper'

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
  end
end
