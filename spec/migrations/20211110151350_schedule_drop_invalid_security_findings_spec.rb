# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleDropInvalidSecurityFindings, :migration, schema: 20211108211434 do
  let_it_be(:background_migration_jobs) { table(:background_migration_jobs) }

  let_it_be(:namespace) { table(:namespaces).create!(name: 'user', path: 'user', type: Namespaces::UserNamespace.sti_name) }
  let_it_be(:project) { table(:projects).create!(namespace_id: namespace.id) }

  let_it_be(:pipelines) { table(:ci_pipelines) }
  let_it_be(:pipeline) { pipelines.create!(project_id: project.id) }

  let_it_be(:ci_builds) { table(:ci_builds) }
  let_it_be(:ci_build) { ci_builds.create! }

  let_it_be(:security_scans) { table(:security_scans) }
  let_it_be(:security_scan) do
    security_scans.create!(
      scan_type: 1,
      status: 1,
      build_id: ci_build.id,
      project_id: project.id,
      pipeline_id: pipeline.id
    )
  end

  let_it_be(:vulnerability_scanners) { table(:vulnerability_scanners) }
  let_it_be(:vulnerability_scanner) { vulnerability_scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }

  let_it_be(:security_findings) { table(:security_findings) }
  let_it_be(:security_finding_without_uuid) do
    security_findings.create!(
      severity: 1,
      confidence: 1,
      scan_id: security_scan.id,
      scanner_id: vulnerability_scanner.id,
      uuid: nil
    )
  end

  let_it_be(:security_finding_with_uuid) do
    security_findings.create!(
      severity: 1,
      confidence: 1,
      scan_id: security_scan.id,
      scanner_id: vulnerability_scanner.id,
      uuid: 'bd95c085-71aa-51d7-9bb6-08ae669c262e'
    )
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
    stub_const("#{described_class}::SUB_BATCH_SIZE", 1)
  end

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  it 'schedules background migrations' do
    migrate!

    expect(background_migration_jobs.count).to eq(1)
    expect(background_migration_jobs.first.arguments).to match_array([security_finding_without_uuid.id, security_finding_without_uuid.id, described_class::SUB_BATCH_SIZE])

    expect(BackgroundMigrationWorker.jobs.size).to eq(1)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, security_finding_without_uuid.id, security_finding_without_uuid.id, described_class::SUB_BATCH_SIZE)
  end
end
