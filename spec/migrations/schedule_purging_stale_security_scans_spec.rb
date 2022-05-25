# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePurgingStaleSecurityScans do
  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:pipelines) { table(:ci_pipelines) }
  let_it_be(:builds) { table(:ci_builds) }
  let_it_be(:security_scans) { table(:security_scans) }

  let_it_be(:namespace) { namespaces.create!(name: "foo", path: "bar") }
  let_it_be(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let_it_be(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let_it_be(:ci_build) { builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build') }

  let!(:security_scan_1) { security_scans.create!(build_id: ci_build.id, scan_type: 1, created_at: 92.days.ago) }
  let!(:security_scan_2) { security_scans.create!(build_id: ci_build.id, scan_type: 2, created_at: 91.days.ago) }

  let(:com?) { false }
  let(:dev_or_test_env?) { false }

  before do
    allow(::Gitlab).to receive(:com?).and_return(com?)
    allow(::Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test_env?)

    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  shared_examples_for 'schedules the background jobs' do
    before do
      # This will not be scheduled as it's not stale
      security_scans.create!(build_id: ci_build.id, scan_type: 3)
    end

    around do |example|
      freeze_time { Sidekiq::Testing.fake! { example.run } }
    end

    it 'creates 2 jobs', :aggregate_failures do
      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to be(2)
      expect(described_class::MIGRATION)
        .to be_scheduled_delayed_migration(2.minutes, security_scan_1.id, security_scan_1.id)
      expect(described_class::MIGRATION)
        .to be_scheduled_delayed_migration(4.minutes, security_scan_2.id, security_scan_2.id)
    end
  end

  context 'when the migration does not run on GitLab.com or `dev_or_test_env`' do
    it 'does not run the migration' do
      expect { migrate! }.not_to change { BackgroundMigrationWorker.jobs.size }
    end
  end

  context 'when the migration runs on GitLab.com' do
    let(:com?) { true }

    it_behaves_like 'schedules the background jobs'
  end

  context 'when the migration runs on dev or test env' do
    let(:dev_or_test_env?) { true }

    it_behaves_like 'schedules the background jobs'
  end
end
