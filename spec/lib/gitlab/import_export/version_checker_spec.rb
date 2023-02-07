# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::VersionChecker, feature_category: :importers do
  include ImportExport::CommonUtil

  let!(:shared) { Gitlab::ImportExport::Shared.new(nil) }

  describe 'bundle a project Git repo' do
    let(:version) { Gitlab::ImportExport.version }
    let(:version_file) { Tempfile.new('VERSION') }

    before do
      allow_any_instance_of(Gitlab::ImportExport::Shared).to receive(:relative_archive_path).and_return('')

      version_file.write(version)
      version_file.rewind

      allow_any_instance_of(described_class).to receive(:version_file).and_return(version_file.path)
    end

    after do
      version_file.close
      version_file.unlink
    end

    it 'returns true if Import/Export have the same version' do
      expect(described_class.check!(shared: shared)).to be true
    end

    context 'newer version' do
      let(:version) { '900.0' }

      it 'returns false if export version is newer' do
        expect(described_class.check!(shared: shared)).to be false
      end

      it 'shows the correct error message' do
        described_class.check!(shared: shared)

        expect(shared.errors.first).to eq("Import version mismatch: Required #{Gitlab::ImportExport.version} but was #{version}")
      end
    end
  end

  describe 'version file access check' do
    it 'does not read a symlink' do
      Dir.mktmpdir do |tmpdir|
        setup_symlink(tmpdir, 'VERSION')

        described_class.check!(shared: shared)

        expect(shared.errors.first).not_to include('test')
      end
    end
  end
end
