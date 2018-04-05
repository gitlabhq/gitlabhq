require 'spec_helper'

describe Gitlab::ImportExport::Importer do
  let(:test_path) { "#{Dir.tmpdir}/importer_spec" }
  let(:shared) { project.import_export_shared }
  let(:project) { create(:project, import_source: File.join(test_path, 'exported-project.gz')) }

  subject(:importer) { described_class.new(project) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(test_path)
    FileUtils.mkdir_p(shared.export_path)
    FileUtils.cp(Rails.root.join('spec', 'fixtures', 'exported-project.gz'), test_path)
  end

  after do
    FileUtils.rm_rf(test_path)
  end

  describe '#execute' do
    it 'succeeds' do
      importer.execute

      expect(shared.errors).to be_empty
    end

    it 'extracts the archive'  do
      expect(Gitlab::ImportExport::FileImporter).to receive(:import).and_call_original

      importer.execute
    end

    it 'checks the version' do
      expect(Gitlab::ImportExport::VersionChecker).to receive(:check!).and_call_original

      importer.execute
    end

    context 'all restores are executed' do
      [
        Gitlab::ImportExport::AvatarRestorer,
        Gitlab::ImportExport::RepoRestorer,
        Gitlab::ImportExport::WikiRestorer,
        Gitlab::ImportExport::UploadsRestorer,
        Gitlab::ImportExport::LfsRestorer
      ].each do |restorer|
        it "calls the #{restorer}" do
          fake_restorer = double(restorer.to_s)

          expect(fake_restorer).to receive(:restore).and_return(true).at_least(1)
          expect(restorer).to receive(:new).and_return(fake_restorer).at_least(1)

          importer.execute
        end
      end

      it 'restores the ProjectTree' do
        expect(Gitlab::ImportExport::ProjectTreeRestorer).to receive(:new).and_call_original

        importer.execute
      end
    end
  end
end
