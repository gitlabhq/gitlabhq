require 'spec_helper'

describe BlobViewer::PackageJson do
  include FakeBlobHelpers

  let(:project) { build(:project) }
  let(:data) do
    <<-SPEC.strip_heredoc
      {
        "name": "module-name",
        "version": "10.3.1"
      }
    SPEC
  end
  let(:blob) { fake_blob(path: 'package.json', data: data) }
  subject { described_class.new(blob) }

  describe '#package_name' do
    it 'returns the package name' do
      expect(subject).to receive(:prepare!)

      expect(subject.package_name).to eq('module-name')
    end
  end
end
