# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespacesRedirectRoutesNamespaceId,
  feature_category: :groups_and_projects do
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:redirect_routes_table) { table(:redirect_routes) }

  let(:connection) { ActiveRecord::Base.connection }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace) { create_namespace('Group') }
  let!(:route_namespace) { create_namespace('Group') }
  let!(:project) do
    projects_table.create!(
      name: 'project1', organization_id: organization.id,
      namespace_id: namespace.id, project_namespace_id: namespace.id
    )
  end

  let(:perform_migration) do
    described_class.new(
      start_id: redirect_routes_table.minimum(:id),
      end_id: redirect_routes_table.maximum(:id),
      batch_table: :redirect_routes,
      batch_column: :id,
      sub_batch_size: redirect_routes_table.count,
      pause_ms: 0,
      connection: connection
    ).perform
  end

  before do
    # This trigger ensures the correctness of new rows, preventing the creation of mock entries
    # that simulate old redirect_routes with non-derived namespace_ids.
    connection.execute('ALTER TABLE redirect_routes DISABLE TRIGGER trigger_sync_redirect_routes_namespace_id')
  end

  after do
    connection.execute('ALTER TABLE redirect_routes ENABLE TRIGGER trigger_sync_redirect_routes_namespace_id')
  end

  context 'when namespace_id is already set' do
    let!(:redirect_route) { create_redirect_route(namespace, namespace_id: route_namespace.id) }

    it 'does not modify the namespace_id' do
      expect { perform_migration }.not_to change { redirect_route.reload.namespace_id }
    end
  end

  context 'when namespace_id is nil' do
    context 'when source is a namespace' do
      let!(:redirect_route) { create_redirect_route(namespace) }

      it 'derives the namespace_id from source id' do
        expect { perform_migration }
          .to change { redirect_route.reload.namespace_id }.from(nil).to(namespace.id)
      end
    end

    context 'when source is a project' do
      let!(:redirect_route) { create_redirect_route(project) }

      it 'keeps the namespace_id as nil' do
        expect { perform_migration }.not_to change { redirect_route.reload.namespace_id }
      end
    end
  end

  def create_namespace(type)
    name = "namespace_#{namespaces_table.count + 1}"
    namespaces_table.create!(name: name, path: name, type: type, organization_id: organization.id)
  end

  def create_redirect_route(source, namespace_id: nil)
    redirect_routes_table.create!(
      path: "path_#{redirect_routes_table.count + 1}",
      source_id: source.id,
      source_type: source.class.sti_name,
      namespace_id: namespace_id
    )
  end
end
