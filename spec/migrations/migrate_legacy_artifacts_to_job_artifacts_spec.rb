require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180427161409_migrate_legacy_artifacts_to_job_artifacts.rb')

describe MigrateLegacyArtifactsToJobArtifacts, :migration, :sidekiq do
  let(:migration_class) { Gitlab::BackgroundMigration::MigrateLegacyArtifacts }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:jobs) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  before do
    namespaces.create!(id: 1, name: 'gitlab', path: 'gitlab-org')
    projects.create!(id: 1, name: 'gitlab', path: 'gitlab-ce', namespace_id: 1)
    pipelines.create!(id: 1, project_id: 1, ref: 'master', sha: 'adf43c3a')
  end

  context 'when a legacy artifacts exists' do
    before do
      jobs.create!(id: 1, commit_id: 1, project_id: 1, status: :success, artifacts_file: 'archive.zip', artifacts_metadata: 'metadata.gz')
    end

    it 'schedules a background migration' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!
  
          expect(migration_name).to be_scheduled_delayed_migration(5.minutes, 1, 1)
          expect(BackgroundMigrationWorker.jobs.size).to eq 1
        end
      end
    end

    context 'when new artifacts has already existed' do
      before do
        job_artifacts.create!(id: 1, project_id: 1, job_id: 1, file_type: 1, size: 123, file: 'archive.zip')
      end

      it 'does not schedule background migrations' do
        Sidekiq::Testing.fake! do
          migrate!
  
          expect(BackgroundMigrationWorker.jobs.size).to eq 0
        end
      end
    end
  end

  context 'when legacy artifacts do not exist' do
    before do
      jobs.create!(id: 1, commit_id: 1, project_id: 1, status: :success)
    end

    it 'does not schedule background migrations' do
      Sidekiq::Testing.fake! do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq 0
      end
    end
  end
end
