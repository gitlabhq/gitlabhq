# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project avatar export and import through the parallel export pipeline',
  feature_category: :importers do
  include Gitlab::ImportExport::CommandLineUtil

  let_it_be(:exporting_user) { create(:user) }
  let_it_be(:project_with_avatar) do
    create(:project, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png'))
  end

  let(:export_job) { create(:project_export_job, project: project_with_avatar) }
  let(:relation_export_path) { "#{Dir.tmpdir}/avatar_export_import_spec_export" }
  let(:relation_archive_path) { "#{Dir.tmpdir}/avatar_export_import_spec_archive" }

  before do
    stub_uploads_object_storage(ImportExportUploader, enabled: false)

    allow(project_with_avatar.import_export_shared).to receive_messages(
      export_path: relation_export_path,
      archive_path: relation_archive_path
    )
  end

  it 'saves the avatar via the real per-relation pipeline and restores it on import' do
    relation_export = create(:project_relation_export,
      relation: Projects::ImportExport::RelationExport::AVATAR_RELATION,
      project_export_job: export_job)

    # Real dispatch through the fix: RelationExportService#relation_saver routes the
    # 'avatar' relation to Gitlab::ImportExport::AvatarSaver, exactly as
    # RelationExportWorker does in production.
    Projects::ImportExport::RelationExportService.new(relation_export, exporting_user, 'jid').execute
    expect(relation_export.reload.finished?).to be(true)

    Dir.mktmpdir do |merged_export_path|
      merger_shared = Gitlab::ImportExport::Shared.new(project_with_avatar)
      allow(merger_shared).to receive(:export_path).and_return(merged_export_path)

      # Real, unmodified merge: the generic step ParallelExportService relies on to
      # fold each relation's tar.gz into the shared export path.
      merge_result = Gitlab::ImportExport::Project::ExportedRelationsMerger.new(
        export_job: export_job, shared: merger_shared
      ).save

      expect(merge_result).to be(true)
      expect(Dir.glob("#{merged_export_path}/avatar/**/dk.png")).to be_one

      Dir.mktmpdir do |full_export_path|
        # A known-good full project tree (proven elsewhere to import successfully),
        # combined with the avatar/ folder merged above -- reproducing the shape of
        # a real parallel-exported archive without re-deriving every other relation.
        untar_zxf(
          archive: Rails.root.join('spec/features/projects/import_export/test_project_export.tar.gz').to_s,
          dir: full_export_path
        )
        FileUtils.cp_r(File.join(merged_export_path, 'avatar'), full_export_path)

        Dir.mktmpdir do |archive_dir|
          archive_file = File.join(archive_dir, 'project_with_avatar_export.tar.gz')
          tar_czf(archive: archive_file, dir: full_export_path)

          target_project = create(:project, creator: exporting_user)
          import_storage_path = "#{Dir.tmpdir}/avatar_export_import_spec_import_storage"

          begin
            allow(Gitlab::ImportExport).to receive(:storage_path).and_return(import_storage_path)
            allow_next_instance_of(Gitlab::ImportExport::FileImporter) do |file_importer|
              allow(file_importer).to receive(:remove_import_file)
            end

            FileUtils.mkdir_p(target_project.import_export_shared.export_path)
            ImportExportUpload.create!(
              project: target_project, user: exporting_user, import_file: File.open(archive_file)
            )

            expect { Gitlab::ImportExport::Importer.new(target_project).execute }.not_to raise_error
            expect(target_project.reload.avatar.file.exists?).to be(true)
          ensure
            FileUtils.rm_rf(import_storage_path)
          end
        end
      end
    end
  end
end
