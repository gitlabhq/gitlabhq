# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanRedirectRoutesRows, feature_category: :groups_and_projects do
  let(:connection) { ApplicationRecord.connection }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace1) { table(:namespaces).create!(name: 'name', path: 'path1', organization_id: organization.id) }
  let!(:namespace2) { table(:namespaces).create!(name: 'name', path: 'path2', organization_id: organization.id) }

  let(:redirect_routes) { table(:redirect_routes) }

  let(:migration_args) do
    {
      start_id: redirect_routes.minimum(:id),
      end_id: redirect_routes.maximum(:id),
      batch_table: :redirect_routes,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'deletes orphan rows' do
    drop_constraint_and_trigger

    project1 = table(:projects).create!(name: 'project', path: 'project1', organization_id: organization.id,
      project_namespace_id: namespace1.id, namespace_id: namespace1.id)
    redirect_route1 = redirect_routes.create!(source_type: 'Project', source_id: project1.id, path: 'foobarbaz1')
    redirect_route1.reload
    expect(redirect_route1.namespace_id).to be_nil

    project2 = table(:projects).create!(name: 'project', path: 'project2', organization_id: organization.id,
      project_namespace_id: namespace2.id, namespace_id: namespace2.id)
    redirect_route2 = redirect_routes.create!(source_type: 'Project', source_id: project2.id, path: 'foobarbaz2')
    redirect_route2.reload
    expect(redirect_route2.namespace_id).to be_nil

    redirect_route3 = redirect_routes.create!(source_type: 'Namespace', source_id: namespace1.id, path: 'foobarbaz3')
    redirect_route3.reload
    expect(redirect_route3.namespace_id).to be_nil

    project1.destroy!
    recreate_constraint_and_trigger

    expect { described_class.new(**migration_args).perform }
      .to change { redirect_routes.count }
      .by(-1)
  end

  private

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS trigger_sync_redirect_routes_namespace_id ON redirect_routes;

        ALTER TABLE redirect_routes DROP CONSTRAINT IF EXISTS check_e82ff70482;
      SQL
    )
  end

  def recreate_constraint_and_trigger
    connection.execute(
      <<~SQL
        ALTER TABLE redirect_routes
          ADD CONSTRAINT check_e82ff70482 CHECK ((namespace_id IS NOT NULL)) NOT VALID;

        CREATE TRIGGER trigger_sync_redirect_routes_namespace_id BEFORE INSERT OR UPDATE
          ON redirect_routes FOR EACH ROW WHEN ((new.namespace_id IS NULL)) EXECUTE FUNCTION
          sync_redirect_routes_namespace_id();
      SQL
    )
  end
end
