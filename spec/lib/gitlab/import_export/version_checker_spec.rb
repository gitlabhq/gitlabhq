require 'spec_helper'

describe Gitlab::ImportExport::VersionChecker, services: true do
  describe 'bundle a project Git repo' do
    let(:shared) { Gitlab::ImportExport::Shared.new(relative_path: '') }
    let(:version) { Gitlab::ImportExport.version }

    before do
      allow(File).to receive(:open).and_return(version)
    end

    it 'returns true if Import/Export have the same version' do
      expect(described_class.check!(shared: shared)).to be true
    end

    context 'newer version' do
      let(:version) { '900.0'}

      it 'returns false if export version is newer' do
        expect(described_class.check!(shared: shared)).to be false
      end

      it 'shows the correct error message' do
        described_class.check!(shared: shared)

        expect(shared.errors.first).to eq("Import version mismatch: Required <= #{Gitlab::ImportExport.version} but was #{version}")
      end
    end
  end
end
