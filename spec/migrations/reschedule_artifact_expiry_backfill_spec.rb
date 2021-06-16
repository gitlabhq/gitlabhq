# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RescheduleArtifactExpiryBackfill, :migration do
  let(:migration_class) { Gitlab::BackgroundMigration::BackfillArtifactExpiryDate }
  let(:migration_name)  { migration_class.to_s.demodulize }

  before do
    table(:namespaces).create!(id: 123, name: 'test_namespace', path: 'test_namespace')
    table(:projects).create!(id: 123, name: 'sample_project', path: 'sample_project', namespace_id: 123)
  end

  it 'correctly schedules background migrations' do
    first_artifact = create_artifact(job_id: 0, expire_at: nil, created_at: Date.new(2020, 06, 21))
    second_artifact = create_artifact(job_id: 1, expire_at: nil, created_at: Date.new(2020, 06, 21))
    create_artifact(job_id: 2, expire_at: Date.yesterday, created_at: Date.new(2020, 06, 21))
    create_artifact(job_id: 3, expire_at: nil, created_at: Date.new(2020, 06, 23))

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
        expect(migration_name).to be_scheduled_migration_with_multiple_args(first_artifact.id, second_artifact.id)
      end
    end
  end

  private

  def create_artifact(params)
    table(:ci_builds).create!(id: params[:job_id], project_id: 123)
    table(:ci_job_artifacts).create!(project_id: 123, file_type: 1, **params)
  end
end
