# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateStatusColumnOfSecurityScans, :suppress_gitlab_schemas_validate_connection do
  before do
    allow(Gitlab).to receive(:ee?).and_return(ee?)
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  context 'when the Gitlab instance is CE' do
    let(:ee?) { false }

    it 'does not run the migration' do
      expect { migrate! }.not_to change { BackgroundMigrationWorker.jobs.size }
    end
  end

  context 'when the Gitlab instance is EE' do
    let(:ee?) { true }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:pipelines) { table(:ci_pipelines) }
    let(:builds) { table(:ci_builds) }
    let(:security_scans) { table(:security_scans) }

    let(:namespace) { namespaces.create!(name: "foo", path: "bar") }
    let(:project) { projects.create!(namespace_id: namespace.id) }
    let(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
    let(:ci_build) { builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build') }

    let!(:security_scan_1) { security_scans.create!(build_id: ci_build.id, scan_type: 1) }
    let!(:security_scan_2) { security_scans.create!(build_id: ci_build.id, scan_type: 2) }

    around do |example|
      freeze_time { Sidekiq::Testing.fake! { example.run } }
    end

    it 'schedules the background jobs', :aggregate_failures do
      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to be(2)
      expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, security_scan_1.id, security_scan_1.id)
      expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, security_scan_2.id, security_scan_2.id)
    end
  end
end
