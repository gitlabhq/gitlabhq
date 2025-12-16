# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphanRedirectRoutesNamespaceRows, migration: :gitlab_main_org, feature_category: :groups_and_projects do
  let(:connection) { ApplicationRecord.connection }
  let(:redirect_routes) { table(:redirect_routes) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  before do
    drop_constraint_and_trigger
  end

  after do
    recreate_constraint_and_trigger
  end

  it 'deletes orphan redirect_routes rows where source_type is Namespace and namespace_id is nil' do
    organization = organizations.create!(name: 'organization', path: 'organization')
    namespace1 = namespaces.create!(name: 'namespace1', path: 'namespace1', organization_id: organization.id)
    namespace2 = namespaces.create!(name: 'namespace2', path: 'namespace2', organization_id: organization.id)

    # Create redirect routes for existing namespaces
    redirect_route1 = redirect_routes.create!(source_type: 'Namespace', source_id: namespace1.id, path: 'route1')
    redirect_route1.reload
    expect(redirect_route1.namespace_id).to be_nil

    # namespace_id IS NULL but source points to an existing namespace (should not be deleted)
    redirect_route2 = redirect_routes.create!(source_type: 'Namespace', source_id: namespace2.id, path: 'route2')
    redirect_route2.reload
    expect(redirect_route2.namespace_id).to be_nil

    # Create a redirect route for a namespace that will be deleted
    redirect_route3 = redirect_routes.create!(source_type: 'Namespace', source_id: namespace1.id, path: 'route3')
    redirect_route3.reload
    expect(redirect_route3.namespace_id).to be_nil

    # Delete namespace1 to create orphan redirect routes
    namespace1.destroy!

    # Verify we have orphan routes before migration
    expect(redirect_routes.where(source_type: 'Namespace', namespace_id: nil).count).to eq(3)

    # Run the migration
    migrate!

    # After migration, only the redirect route for the existing namespace should remain
    expect(redirect_routes.where(source_type: 'Namespace').count).to eq(1)
    expect(redirect_routes.find_by(path: 'route2')).to be_present
    expect(redirect_routes.find_by(path: 'route1')).to be_nil
    expect(redirect_routes.find_by(path: 'route3')).to be_nil
  end

  it 'does not delete redirect_routes with source_type Project' do
    organization = organizations.create!(name: 'organization', path: 'organization')
    namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id)

    # Create a redirect route with source_type Project
    redirect_route = redirect_routes.create!(source_type: 'Project', source_id: 1, path: 'project_route')
    redirect_route.reload
    expect(redirect_route.namespace_id).to be_nil

    # Run the migration
    migrate!

    # The Project redirect route should still exist
    expect(redirect_routes.find_by(path: 'project_route')).to be_present
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
