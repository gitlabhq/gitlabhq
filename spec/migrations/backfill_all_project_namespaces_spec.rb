# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillAllProjectNamespaces, :migration, feature_category: :subgroups do
  let!(:migration) { described_class::MIGRATION }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:user_namespace) { namespaces.create!(name: 'user1', path: 'user1', visibility_level: 20, type: 'User') }
  let(:parent_group1) { namespaces.create!(name: 'parent_group1', path: 'parent_group1', visibility_level: 20, type: 'Group') }
  let!(:parent_group1_project) { projects.create!(name: 'parent_group1_project', path: 'parent_group1_project', namespace_id: parent_group1.id, visibility_level: 20) }
  let!(:user_namespace_project) { projects.create!(name: 'user1_project', path: 'user1_project', namespace_id: user_namespace.id, visibility_level: 20) }

  describe '#up' do
    it 'schedules background jobs for each batch of namespaces' do
      migrate!

      expect(migration).to have_scheduled_batched_migration(
        table_name: :projects,
        column_name: :id,
        job_arguments: [nil, 'up'],
        interval: described_class::DELAY_INTERVAL
      )
    end
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
