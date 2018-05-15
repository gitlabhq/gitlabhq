require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateLegacyArtifacts, :migration, schema: 20180427161409 do
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:jobs) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  context 'when legacy artifacts exist' do
    before do
      projects.create!(id: 123, name: 'gitlab', path: 'gitlab-ce')
      pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')
  
      jobs.create!(id: 1, commit_id: 1, project_id: 123, status: :success)
      jobs.create!(id: 2, commit_id: 1, project_id: 123, status: :success)
      jobs.create!(id: 3, commit_id: 1, project_id: 123, status: :failed)
      jobs.create!(id: 4, commit_id: 1, project_id: 123, status: :success)
      jobs.create!(id: 5, commit_id: 1, project_id: 123, status: :pending)
      jobs.create!(id: 6, commit_id: 1, project_id: 123, status: :pending)
    end

    it 'migrates' do

      # And file access
    end

    context 'when job_artifacts has been already existed' do
      it 'migrates' do

        # And file access
      end
    end
  end

  context 'when legacy artifacts do not exist' do

  end

  def create_file(job, object_storage = false)
    Tmpfile.create
    JobArtifactUploader.
    job.update_column(artifacts_file: nil)
    job.update_column(artifacts_file_store: nil)
    job.update_column(artifacts_size: nil)
    job.update_column(artifacts_metadata: nil)
    job.update_column(artifacts_metadata_store: nil)
  end
end
