require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180816161409_migrate_legacy_artifacts_to_job_artifacts.rb')

describe MigrateLegacyArtifactsToJobArtifacts, :migration, :sidekiq do
  let(:migration_class) { Gitlab::BackgroundMigration::MigrateLegacyArtifacts }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:jobs) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(name: 'gitlab', path: 'gitlab-ce', namespace_id: namespace.id) }
  let(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a') }
  let(:archive_file_type) { Gitlab::BackgroundMigration::MigrateLegacyArtifacts::ARCHIVE_FILE_TYPE }
  let(:metadata_file_type) { Gitlab::BackgroundMigration::MigrateLegacyArtifacts::METADATA_FILE_TYPE }
  let(:local_store) { ::ObjectStorage::Store::LOCAL }
  let(:remote_store) { ::ObjectStorage::Store::REMOTE }
  let(:legacy_location) { Gitlab::BackgroundMigration::MigrateLegacyArtifacts::LEGACY_PATH_FILE_LOCATION }

  context 'when legacy artifacts exist' do
    before do
      jobs.create!(id: 1, commit_id: pipeline.id, project_id: project.id, status: :success, artifacts_file: 'archive.zip')
      jobs.create!(id: 2, commit_id: pipeline.id, project_id: project.id, status: :failed, artifacts_metadata: 'metadata.gz')
      jobs.create!(id: 3, commit_id: pipeline.id, project_id: project.id, status: :failed, artifacts_file: 'archive.zip', artifacts_metadata: 'metadata.gz')
      jobs.create!(id: 4, commit_id: pipeline.id, project_id: project.id, status: :running)
      jobs.create!(id: 5, commit_id: pipeline.id, project_id: project.id, status: :success, artifacts_file: 'archive.zip', artifacts_file_store: remote_store, artifacts_metadata: 'metadata.gz')
      jobs.create!(id: 6, commit_id: pipeline.id, project_id: project.id, status: :failed, artifacts_file: 'archive.zip', artifacts_metadata: 'metadata.gz')
    end

    it 'schedules a background migration' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!

          expect(migration_name).to be_scheduled_delayed_migration(5.minutes, 1, 6)
          expect(BackgroundMigrationWorker.jobs.size).to eq 1
        end
      end
    end

    it 'migrates legacy artifacts to ci_job_artifacts table' do
      migrate!

      expect(job_artifacts.order(:job_id, :file_type).pluck('project_id, job_id, file_type, file_store, size, expire_at, file, file_sha256, file_location'))
        .to eq([[project.id, 1, archive_file_type, local_store, nil, nil, 'archive.zip', nil, legacy_location],
                [project.id, 3, archive_file_type, local_store, nil, nil, 'archive.zip', nil, legacy_location],
                [project.id, 3, metadata_file_type, local_store, nil, nil, 'metadata.gz', nil, legacy_location],
                [project.id, 5, archive_file_type, remote_store, nil, nil, 'archive.zip', nil, legacy_location],
                [project.id, 5, metadata_file_type, local_store, nil, nil, 'metadata.gz', nil, legacy_location],
                [project.id, 6, archive_file_type, local_store, nil, nil, 'archive.zip', nil, legacy_location],
                [project.id, 6, metadata_file_type, local_store, nil, nil, 'metadata.gz', nil, legacy_location]])
    end
  end

  context 'when legacy artifacts do not exist' do
    before do
      jobs.create!(id: 1, commit_id: pipeline.id, project_id: project.id, status: :success)
      jobs.create!(id: 2, commit_id: pipeline.id, project_id: project.id, status: :failed, artifacts_metadata: 'metadata.gz')
    end

    it 'does not schedule background migrations' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq 0
        end
      end
    end
  end
end
