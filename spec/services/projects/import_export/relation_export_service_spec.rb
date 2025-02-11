# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationExportService, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  subject(:service) { described_class.new(relation_export, user, 'jid') }

  let_it_be(:project_export_job) { create(:project_export_job) }
  let_it_be(:user) { create(:user) }
  let_it_be(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let_it_be(:archive_path) { "#{Dir.tmpdir}/project_archive_spec" }

  let(:relation_export) { create(:project_relation_export, relation: relation, project_export_job: project_export_job) }

  before do
    stub_uploads_object_storage(ImportExportUploader, enabled: false)

    allow(project_export_job.project.import_export_shared).to receive(:export_path).and_return(export_path)
    allow(project_export_job.project.import_export_shared).to receive(:archive_path).and_return(archive_path)
    allow(FileUtils).to receive(:rm_rf).with(any_args).and_call_original
  end

  describe '#execute' do
    let(:relation) { 'labels' }

    it 'removes temporary paths used to export files' do
      expect(FileUtils).to receive(:rm_rf).with(export_path)
      expect(FileUtils).to receive(:rm_rf).with(archive_path)

      service.execute
    end

    context 'when saver fails to export relation' do
      before do
        allow_next_instance_of(Gitlab::ImportExport::Project::RelationSaver) do |saver|
          allow(saver).to receive(:save).and_return(false)
        end
      end

      it 'raises error and logs failed message' do
        expect_next_instance_of(Gitlab::Export::Logger) do |logger|
          expect(logger).to receive(:warn).with(
            export_error: '',
            message: 'Project relation export failed',
            relation: relation_export.relation,
            project_export_job_id: project_export_job.id,
            project_id: project_export_job.project.id,
            project_name: project_export_job.project.name
          )
        end

        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
      end
    end

    describe 'relation name and saver class' do
      where(:relation_name, :saver) do
        Projects::ImportExport::RelationExport::UPLOADS_RELATION | Gitlab::ImportExport::UploadsSaver
        Projects::ImportExport::RelationExport::REPOSITORY_RELATION | Gitlab::ImportExport::RepoSaver
        Projects::ImportExport::RelationExport::WIKI_REPOSITORY_RELATION | Gitlab::ImportExport::WikiRepoSaver
        Projects::ImportExport::RelationExport::LFS_OBJECTS_RELATION | Gitlab::ImportExport::LfsSaver
        Projects::ImportExport::RelationExport::SNIPPETS_REPOSITORY_RELATION | Gitlab::ImportExport::SnippetsRepoSaver
        Projects::ImportExport::RelationExport::DESIGN_REPOSITORY_RELATION | Gitlab::ImportExport::DesignRepoSaver
        Projects::ImportExport::RelationExport::ROOT_RELATION | Gitlab::ImportExport::Project::RelationSaver
        'labels' | Gitlab::ImportExport::Project::RelationSaver
      end

      with_them do
        let(:relation) { relation_name }

        it 'exports relation using correct saver' do
          expect(saver).to receive(:new).and_call_original

          service.execute
        end

        it 'assigns finished status and relation file' do
          service.execute

          expect(relation_export.finished?).to eq(true)
          expect(relation_export.upload.export_file.filename).to eq("#{relation}.tar.gz")
        end
      end
    end
  end
end
