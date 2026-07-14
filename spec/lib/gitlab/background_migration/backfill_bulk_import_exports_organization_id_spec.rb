# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBulkImportExportsOrganizationId, feature_category: :importers do
  let(:connection) { ApplicationRecord.connection }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:user) do
    table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10,
      organization_id: organization.id)
  end

  let!(:namespace) { table(:namespaces).create!(name: 'name', path: 'path', organization_id: organization.id) }
  let!(:project) do
    table(:projects).create!(name: 'project', path: 'project', organization_id: organization.id,
      project_namespace_id: namespace.id, namespace_id: namespace.id)
  end

  let(:bulk_import_exports) { table(:bulk_import_exports) }
  let(:migration_args) do
    {
      start_id: bulk_import_exports.minimum(:id),
      end_id: bulk_import_exports.maximum(:id),
      batch_table: :bulk_import_exports,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'backfills organization_id from the related project or group', :aggregate_failures do
    drop_trigger

    project_export = bulk_import_exports.create!(
      project_id: project.id,
      group_id: nil,
      relation: 'project_export',
      organization_id: nil
    )
    project_export.reload
    expect(project_export.organization_id).to be_nil

    group_export = bulk_import_exports.create!(
      project_id: nil,
      group_id: namespace.id,
      relation: 'group_export',
      organization_id: nil
    )
    group_export.reload
    expect(group_export.organization_id).to be_nil

    recreate_trigger
    described_class.new(**migration_args).perform

    project_export.reload
    expect(project_export.organization_id).to eq(organization.id)

    group_export.reload
    expect(group_export.organization_id).to eq(organization.id)
  end

  private

  def drop_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS trigger_bulk_import_exports_sharding_key ON bulk_import_exports;
      SQL
    )
  end

  def recreate_trigger
    connection.execute(
      <<~SQL
        CREATE TRIGGER trigger_bulk_import_exports_sharding_key BEFORE INSERT OR UPDATE
          ON bulk_import_exports FOR EACH ROW EXECUTE FUNCTION bulk_import_exports_sharding_key();
      SQL
    )
  end
end
