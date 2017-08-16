require 'spec_helper'

describe BlobViewer::PodspecJson do
  include FakeBlobHelpers

  let(:project) { build_stubbed(:project) }
  let(:data) do
    <<-SPEC.strip_heredoc
      {
        "name": "AFNetworking",
        "version": "2.0.0"
      }
    SPEC
  end
  let(:blob) { fake_blob(path: 'AFNetworking.podspec.json', data: data) }
  subject { described_class.new(blob) }

  describe '#package_name' do
    it 'returns the package name' do
      expect(subject).to receive(:prepare!)

      expect(subject.package_name).to eq('AFNetworking')
    end
  end
end
