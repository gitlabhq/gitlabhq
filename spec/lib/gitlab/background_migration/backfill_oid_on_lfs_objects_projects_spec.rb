# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOidOnLfsObjectsProjects, feature_category: :source_code_management do
  let(:connection) { ApplicationRecord.connection }

  let(:projects_table) { table(:projects) }
  let(:lfs_objects_table) { table(:lfs_objects) }
  let(:lfs_objects_projects_table) { table(:lfs_objects_projects) }
  let(:lfs_object_size) { 20 }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let(:namespace) { table(:namespaces).create!(name: 'ns1', path: 'ns1', organization_id: organization.id) }

  let(:project) do
    projects_table.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:lfs_object) do
    lfs_objects_table.create!(
      oid: 'f2b0a1e7550e9b718dafc9b525a04879a766de62e4fbdfc46593d47f7ab74636',
      size: lfs_object_size
    )
  end

  let!(:lfs_objects_project) do
    lfs_objects_projects_table.create!(project_id: project.id, lfs_object_id: lfs_object.id, repository_type: 0)
  end

  let(:job_params) do
    {
      batch_table: :lfs_objects_projects,
      batch_column: :id,
      pause_ms: 0,
      sub_batch_size: QueueBackfillOidOnLfsObjectsProjects::SUB_BATCH_SIZE,
      connection: connection
    }
  end

  let(:migration) { described_class.new(**job_params) }

  it "backfills oid from the lfs_objects" do
    expect(lfs_objects_project.oid).to be_nil

    migration.perform

    expect(lfs_objects_project.reload.oid).to eq(lfs_object.oid)
  end
end
