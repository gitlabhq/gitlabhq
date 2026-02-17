# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedDependencyScans, feature_category: :software_composition_analysis do
  let(:security_scans) { table(:security_scans, database: :sec) }
  let(:ci_builds) { table(:p_ci_builds, primary_key: :id, database: :ci) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  # Enum constants for readability
  let(:scan_type_sast) { 1 }
  let(:scan_type_dependency_scanning) { 2 }
  let(:status_created) { 0 }
  let(:status_succeeded) { 1 }

  # Threshold for "stale" scans (matches implementation)
  let(:stale_threshold) { 7.days }

  let!(:organization) { organizations.create!(name: 'test-org', path: 'test-org') }
  let!(:shared_project) { create_project('shared') }

  describe '#perform' do
    subject(:perform_migration) { described_class.new(**migration_args).perform }

    context 'when deleting orphaned dependency scans' do
      let!(:orphaned_scan_old) do
        create_scan(age: 10.days, scan_type: scan_type_dependency_scanning, status: status_created)
      end

      let!(:orphaned_scan_stale) do
        create_scan(age: 8.days, scan_type: scan_type_dependency_scanning, status: status_created)
      end

      let!(:recent_created_scan) do
        create_scan(age: 2.days, scan_type: scan_type_dependency_scanning, status: status_created)
      end

      let!(:processed_scan) do
        create_scan(age: 10.days, scan_type: scan_type_dependency_scanning, status: status_succeeded)
      end

      let!(:sast_scan_created) do
        create_scan(age: 10.days, scan_type: scan_type_sast, status: status_created)
      end

      it 'deletes only stale dependency scanning scans in created status' do
        expect { perform_migration }
          .to change { security_scans.count }.from(5).to(3)
          .and change { security_scans.exists?(orphaned_scan_old.id) }.from(true).to(false)
          .and change { security_scans.exists?(orphaned_scan_stale.id) }.from(true).to(false)
      end

      it 'preserves recent scans in created status' do
        perform_migration

        expect(security_scans.exists?(recent_created_scan.id)).to be true
      end

      it 'preserves scans that have been processed (non-created status)' do
        perform_migration

        expect(security_scans.exists?(processed_scan.id)).to be true
      end

      it 'preserves non-dependency-scanning scan types' do
        perform_migration

        expect(security_scans.exists?(sast_scan_created.id)).to be true
      end

      it 'is idempotent' do
        2.times { perform_migration }

        expect(security_scans.count).to eq(3)
      end
    end

    context 'with boundary conditions around the stale threshold' do
      let!(:scan_at_threshold) do
        create_scan(age: stale_threshold, scan_type: scan_type_dependency_scanning, status: status_created)
      end

      let!(:scan_just_before_threshold) do
        create_scan(age: stale_threshold - 1.hour, scan_type: scan_type_dependency_scanning, status: status_created)
      end

      let!(:scan_just_after_threshold) do
        create_scan(age: stale_threshold + 1.hour, scan_type: scan_type_dependency_scanning, status: status_created)
      end

      it 'deletes scans older than the threshold' do
        perform_migration

        expect(security_scans.exists?(scan_just_after_threshold.id)).to be false
      end

      it 'preserves scans newer than the threshold' do
        perform_migration

        expect(security_scans.exists?(scan_just_before_threshold.id)).to be true
      end

      it 'deletes scans exactly at the threshold (uses >= comparison)' do
        perform_migration

        expect(security_scans.exists?(scan_at_threshold.id)).to be false
      end
    end

    context 'with an empty batch' do
      it 'handles gracefully when no scans match criteria' do
        # Only create scans that should NOT be deleted
        create_scan(age: 2.days, scan_type: scan_type_dependency_scanning, status: status_created)

        expect { perform_migration }.not_to change { security_scans.count }
      end
    end

    context 'with various scan types' do
      # Ensure all scan types other than dependency_scanning are preserved
      let(:other_scan_types) { [1, 3, 4, 5, 6, 7, 8] } # All types except 2 (dependency_scanning)

      before do
        other_scan_types.each do |scan_type|
          create_scan(age: 10.days, scan_type: scan_type, status: status_created)
        end
      end

      it 'only targets dependency_scanning type' do
        expect { perform_migration }.not_to change { security_scans.count }
      end
    end
  end

  private

  def migration_args
    min, max = security_scans.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min || 0,
      end_id: max || 0,
      batch_table: 'security_scans',
      batch_column: 'id',
      sub_batch_size: 100,
      pause_ms: 0,
      connection: SecApplicationRecord.connection
    }
  end

  def create_scan(age:, scan_type:, status:, project: shared_project)
    build = ci_builds.create!(project_id: project.id, partition_id: 100)
    timestamp = age.ago

    security_scans.create!(
      build_id: build.id,
      project_id: project.id,
      scan_type: scan_type,
      status: status,
      created_at: timestamp,
      updated_at: timestamp
    )
  end

  def create_project(name)
    user = users.create!(
      username: "user-#{name}",
      email: "user-#{name}@example.com",
      encrypted_password: 'password',
      projects_limit: 10,
      organization_id: organization.id
    )

    namespace = namespaces.create!(
      name: "group-#{name}",
      path: "group-#{name}",
      owner_id: user.id,
      type: 'User',
      organization_id: organization.id
    )

    project_namespace = namespaces.create!(
      name: "project-#{name}",
      path: "project-#{name}",
      owner_id: user.id,
      type: 'User',
      organization_id: organization.id
    )

    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      name: "project-#{name}",
      path: "project-#{name}",
      organization_id: organization.id
    )
  end
end
