# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupBulkImportExportUploadUploadStatesWithNullProjectId, feature_category: :geo_replication do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:uploads) { table(:bulk_import_export_upload_uploads) }
  let(:states) { table(:bulk_import_export_upload_upload_states) }

  let!(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let!(:group) { namespaces.create!(name: 'group', path: 'group', organization_id: organization.id) }
  let!(:project_namespace) do
    namespaces.create!(name: 'project', path: 'project', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      namespace_id: project_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  # The sharding key triggers copy project_id/namespace_id from the parent
  # upload, so each state row needs one.
  let!(:project_owned_upload_id) { create_upload(project_id: project.id) }
  let!(:group_owned_upload_id) { create_upload(namespace_id: group.id) }

  let!(:project_owned_state) do
    states.create!(bulk_import_export_upload_upload_id: project_owned_upload_id)
  end

  let!(:group_owned_state) do
    states.create!(bulk_import_export_upload_upload_id: group_owned_upload_id)
  end

  describe '#down' do
    it 'removes state rows with a NULL project_id' do
      migrate!
      schema_migrate_down!

      expect(states.where(project_id: nil)).to be_empty
      expect(states.pluck(:id)).to contain_exactly(project_owned_state.id)
    end
  end

  # uploads has a composite primary key, so read the generated id back by path
  # rather than off the returned record.
  def create_upload(project_id: nil, namespace_id: nil)
    path = "export-#{SecureRandom.hex}.tar.gz"

    uploads.create!(
      size: 100,
      model_id: 1,
      model_type: 'BulkImports::ExportUpload',
      path: path,
      uploader: 'ImportExportUploader',
      project_id: project_id,
      namespace_id: namespace_id,
      created_at: Time.current
    )

    uploads.find_by!(path: path).attributes['id']
  end
end
