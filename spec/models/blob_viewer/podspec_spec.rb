require 'spec_helper'

describe BlobViewer::Podspec do
  include FakeBlobHelpers

  let(:project) { build_stubbed(:project) }
  let(:data) do
    <<-SPEC.strip_heredoc
      Pod::Spec.new do |spec|
        spec.name         = 'Reachability'
        spec.version      = '3.1.0'
      end
    SPEC
  end
  let(:blob) { fake_blob(path: 'Reachability.podspec', data: data) }
  subject { described_class.new(blob) }

  describe '#package_name' do
    it 'returns the package name' do
      expect(subject).to receive(:prepare!)

      expect(subject.package_name).to eq('Reachability')
    end
  end
end
