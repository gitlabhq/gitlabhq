# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleMigrateSecurityScans, :sidekiq do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  let(:namespace) { namespaces.create!(name: "foo", path: "bar") }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:job) { builds.create! }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
    stub_const("#{described_class.name}::INTERVAL", 5.minutes.to_i)
  end

  context 'no security job artifacts' do
    before do
      table(:ci_job_artifacts)
    end

    it 'does not schedule migration' do
      Sidekiq::Testing.fake! do
        migrate!

        expect(BackgroundMigrationWorker.jobs).to be_empty
      end
    end
  end

  context 'has security job artifacts' do
    let!(:job_artifact_1) { job_artifacts.create!(project_id: project.id, job_id: job.id, file_type: 5) }
    let!(:job_artifact_2) { job_artifacts.create!(project_id: project.id, job_id: job.id, file_type: 8) }

    it 'schedules migration of security scans' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migration.up

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, job_artifact_1.id, job_artifact_1.id)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, job_artifact_2.id, job_artifact_2.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end

  context 'has non-security job artifacts' do
    let!(:job_artifact_1) { job_artifacts.create!(project_id: project.id, job_id: job.id, file_type: 4) }
    let!(:job_artifact_2) { job_artifacts.create!(project_id: project.id, job_id: job.id, file_type: 9) }

    it 'schedules migration of security scans' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migration.up

          expect(BackgroundMigrationWorker.jobs).to be_empty
        end
      end
    end
  end
end
