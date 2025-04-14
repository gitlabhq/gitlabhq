# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedRoutes, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:routes) { table(:routes) }
  let(:organization) { organizations.create!(name: 'Foobar', path: 'path1') }
  let!(:namespace) do
    namespaces.create!(name: 'Group', type: 'Group', path: 'group', organization_id: organization.id)
  end

  subject(:background_migration) do
    described_class.new(
      start_id: routes.minimum(:id),
      end_id: routes.maximum(:id),
      batch_table: :routes,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  before do
    # Remove constraint so we can create invalid records
    ApplicationRecord.connection.execute("ALTER TABLE routes DROP CONSTRAINT fk_679ff8213d;")

    routes.create!(path: 'route1', source_id: namespace.id, source_type: 'Namespace', namespace_id: namespace.id)
    routes.create!(
      path: 'orphaned_route', source_id: non_existing_record_id, source_type: 'Namespace',
      namespace_id: non_existing_record_id
    )
  end

  after do
    # Re-create constraint after the test
    ApplicationRecord.connection.execute(<<~SQL)
      ALTER TABLE ONLY routes
          ADD CONSTRAINT fk_679ff8213d FOREIGN KEY (namespace_id) REFERENCES namespaces(id) ON DELETE CASCADE NOT VALID;
    SQL
  end

  describe '#perform' do
    it 'deletes the orphaned routes' do
      expect { background_migration }.to change { routes.count }.from(2).to(1)
    end
  end
end
