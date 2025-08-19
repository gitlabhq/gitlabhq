# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedGroups, feature_category: :groups_and_projects do
  before do
    stub_feature_flags(organization_users_internal: false)
  end

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:organization) { organizations.create!(name: 'Foobar', path: 'path1') }
  let!(:parent) { namespaces.create!(name: 'Group', type: 'Group', path: 'space1', organization_id: organization.id) }
  let!(:group) { namespaces.create!(name: 'GitLab', type: 'Group', path: 'group1', organization_id: organization.id) }
  let!(:admin_bot) { ::Users::Internal.admin_bot }
  let!(:orphaned_groups) do
    (1..4).map do |i|
      namespaces.create!(
        name: "Group #{i}",
        path: "orphaned_group_#{i}",
        type: 'Group',
        parent_id: parent.id,
        organization_id: organization.id
      )
    end
  end

  subject(:background_migration) do
    described_class.new(
      start_id: namespaces.without(parent).minimum(:id),
      end_id: namespaces.maximum(:id),
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  describe '#perform' do
    before do
      # Remove constraint so we can create invalid records
      ApplicationRecord.connection.execute("ALTER TABLE namespaces DROP CONSTRAINT fk_7f813d8c90;")
      (1..4).map do |i|
        namespaces.create!(
          name: "Group #{i}", path: "group_#{i}", type: 'Group', parent_id: group.id, organization_id: organization.id
        )
      end
    end

    after do
      # Re-create constraint after the test
      ApplicationRecord.connection.execute(<<~SQL)
        ALTER TABLE ONLY namespaces ADD CONSTRAINT fk_7f813d8c90
        FOREIGN KEY (parent_id) REFERENCES namespaces(id) ON DELETE RESTRICT NOT VALID;
      SQL
    end

    it 'enqueues ::GroupDestroyWorker for each group whose parent\'s do not exist and destroys them', :sidekiq_inline do
      parent.destroy!

      expect { background_migration }.to change { namespaces.count }.from(10).to(6)
        .and change { namespaces.where(id: orphaned_groups.pluck(:id)).count }.from(4).to(0)
    end
  end
end
