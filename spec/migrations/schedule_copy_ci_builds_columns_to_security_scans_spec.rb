# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleCopyCiBuildsColumnsToSecurityScans do
  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:ci_pipelines) { table(:ci_pipelines) }
  let_it_be(:ci_builds) { table(:ci_builds) }
  let_it_be(:security_scans) { table(:security_scans) }

  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:pipeline) { ci_pipelines.create!(status: "success")}

  let!(:build1) { ci_builds.create!(commit_id: pipeline.id, type: 'Ci::Build', project_id: project.id) }
  let!(:build2) { ci_builds.create!(commit_id: pipeline.id, type: 'Ci::Build', project_id: project.id) }
  let!(:build3) { ci_builds.create!(commit_id: pipeline.id, type: 'Ci::Build', project_id: project.id) }

  let!(:scan1) { security_scans.create!(build_id: build1.id, scan_type: 1) }
  let!(:scan2) { security_scans.create!(build_id: build2.id, scan_type: 1) }
  let!(:scan3) { security_scans.create!(build_id: build3.id, scan_type: 1) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
    allow_next_instance_of(Gitlab::BackgroundMigration::CopyCiBuildsColumnsToSecurityScans) do |instance|
      allow(instance).to receive(:mark_job_as_succeeded)
    end
  end

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  it 'schedules background migrations', :aggregate_failures do
    migrate!

    expect(BackgroundMigrationWorker.jobs.size).to eq(2)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, scan1.id, scan2.id)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, scan3.id, scan3.id)
  end
end
