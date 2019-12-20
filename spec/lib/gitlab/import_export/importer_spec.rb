# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::Importer do
  let(:user) { create(:user) }
  let(:test_path) { "#{Dir.tmpdir}/importer_spec" }
  let(:shared) { project.import_export_shared }
  let(:project) { create(:project) }
  let(:import_file) { fixture_file_upload('spec/features/projects/import_export/test_project_export.tar.gz') }

  subject(:importer) { described_class.new(project) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(test_path)
    allow_any_instance_of(Gitlab::ImportExport::FileImporter).to receive(:remove_import_file)
    stub_uploads_object_storage(FileUploader)

    FileUtils.mkdir_p(shared.export_path)
    ImportExportUpload.create(project: project, import_file: import_file)
  end

  after do
    FileUtils.rm_rf(test_path)
  end

  describe '#execute' do
    it 'succeeds' do
      importer.execute

      expect(shared.errors).to be_empty
    end

    it 'extracts the archive' do
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
        Gitlab::ImportExport::LfsRestorer,
        Gitlab::ImportExport::StatisticsRestorer
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

      it 'removes the import file' do
        expect(importer).to receive(:remove_import_file).and_call_original

        importer.execute

        expect(project.import_export_upload.import_file&.file).to be_nil
      end

      it 'sets the correct visibility_level when visibility level is a string' do
        project.create_or_update_import_data(
          data: { override_params: { visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s } }
        )

        importer.execute

        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    context 'when project successfully restored' do
      let!(:existing_project) { create(:project, namespace: user.namespace) }
      let(:project) { create(:project, namespace: user.namespace, name: 'whatever', path: 'whatever') }

      before do
        restorers = double(:restorers, all?: true)

        allow(subject).to receive(:import_file).and_return(true)
        allow(subject).to receive(:check_version!).and_return(true)
        allow(subject).to receive(:restorers).and_return(restorers)
        allow(project).to receive(:import_data).and_return(double(data: { 'original_path' => existing_project.path }))
      end

      context 'when import_data' do
        context 'has original_path' do
          it 'overwrites existing project' do
            expect_any_instance_of(::Projects::OverwriteProjectService).to receive(:execute).with(existing_project)

            subject.execute
          end
        end

        context 'has not original_path' do
          before do
            allow(project).to receive(:import_data).and_return(double(data: {}))
          end

          it 'does not call the overwrite service' do
            expect_any_instance_of(::Projects::OverwriteProjectService).not_to receive(:execute).with(existing_project)

            subject.execute
          end
        end
      end
    end
  end
end
