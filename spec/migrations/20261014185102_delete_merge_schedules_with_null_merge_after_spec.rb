# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe DeleteMergeSchedulesWithNullMergeAfter, migration: :gitlab_main_org, feature_category: :code_review_workflow do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_schedules) { table(:merge_request_merge_schedules) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let!(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:merge_request_with_null_merge_after) do
    merge_requests.create!(
      title: 'MR with null merge_after',
      source_branch: 'feature',
      target_branch: 'master',
      target_project_id: project.id
    )
  end

  let!(:merge_request_with_merge_after) do
    merge_requests.create!(
      title: 'MR with merge_after',
      source_branch: 'feature-2',
      target_branch: 'master',
      target_project_id: project.id
    )
  end

  # The NOT VALID NOT NULL check constraint (added by migration 20261014185101)
  # blocks new inserts with merge_after: nil. Drop it while seeding the invalid
  # row, then re-add it as NOT VALID so the migration runs against the
  # production-like schema (constraint present but not yet validated).
  let!(:schedule_with_null_merge_after) do
    connection = merge_schedules.connection
    connection.remove_check_constraint(:merge_request_merge_schedules, name: 'check_39780e2606')

    record = merge_schedules.create!(
      merge_request_id: merge_request_with_null_merge_after.id,
      project_id: project.id,
      merge_after: nil
    )

    connection.add_check_constraint(
      :merge_request_merge_schedules,
      'merge_after IS NOT NULL',
      name: 'check_39780e2606',
      validate: false
    )

    record
  end

  let!(:schedule_with_merge_after) do
    merge_schedules.create!(
      merge_request_id: merge_request_with_merge_after.id,
      project_id: project.id,
      merge_after: 1.day.from_now
    )
  end

  describe '#up' do
    it 'deletes merge schedules with null merge_after and keeps those with a value', :aggregate_failures do
      migrate!

      expect(merge_schedules.where(id: schedule_with_null_merge_after.id)).to be_empty
      expect(merge_schedules.where(id: schedule_with_merge_after.id)).to exist
    end
  end

  describe '#down' do
    it 'is a no-op' do
      migrate!

      expect { schema_migrate_down! }.not_to change { merge_schedules.count }
    end
  end
end
