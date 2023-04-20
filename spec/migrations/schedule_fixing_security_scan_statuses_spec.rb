# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleFixingSecurityScanStatuses,
  :suppress_gitlab_schemas_validate_connection, feature_category: :vulnerability_management do
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:pipelines) { table(:ci_pipelines) }
  let!(:builds) { table(:ci_builds) }
  let!(:security_scans) { table(:security_scans) }

  let!(:namespace) { namespaces.create!(name: "foo", path: "bar") }
  let!(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let!(:pipeline) do
    pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success', partition_id: 1)
  end

  let!(:ci_build) { builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build', partition_id: 1) }

  let!(:security_scan_1) { security_scans.create!(build_id: ci_build.id, scan_type: 1, created_at: 91.days.ago) }
  let!(:security_scan_2) { security_scans.create!(build_id: ci_build.id, scan_type: 2) }

  let(:com?) { false }
  let(:dev_or_test_env?) { false }
  let(:migration) { described_class::MIGRATION }

  before do
    allow(::Gitlab).to receive(:com?).and_return(com?)
    allow(::Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test_env?)

    migrate!
  end

  describe '#up' do
    shared_examples_for 'scheduler for fixing the security scans status' do
      it 'schedules background job' do
        expect(migration).to have_scheduled_batched_migration(
          table_name: :security_scans,
          column_name: :id,
          interval: 2.minutes,
          batch_size: 10_000,
          max_batch_size: 50_000,
          sub_batch_size: 100,
          batch_min_value: security_scan_2.id
        )
      end
    end

    context 'when the migration does not run on GitLab.com or development environment' do
      it 'does not schedule the migration' do
        expect('FixSecurityScanStatuses').not_to have_scheduled_batched_migration
      end
    end

    context 'when the migration runs on GitLab.com' do
      let(:com?) { true }

      it_behaves_like 'scheduler for fixing the security scans status'
    end

    context 'when the migration runs on dev environment' do
      let(:dev_or_test_env?) { true }

      it_behaves_like 'scheduler for fixing the security scans status'
    end
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
