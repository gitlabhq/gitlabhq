# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectNamespacesForGroup, feature_category: :subgroups do
  let!(:migration) { described_class::MIGRATION }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:parent_group1) { namespaces.create!(name: 'parent_group1', path: 'parent_group1', visibility_level: 20, type: 'Group') }
  let!(:parent_group1_project) { projects.create!(name: 'parent_group1_project', path: 'parent_group1_project', namespace_id: parent_group1.id, visibility_level: 20) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  describe '#up' do
    before do
      stub_const("BackfillProjectNamespacesForGroup::GROUP_ID", parent_group1.id)
    end

    it 'schedules background jobs for each batch of namespaces' do
      migrate!

      expect(migration).to have_scheduled_batched_migration(
        table_name: :projects,
        column_name: :id,
        job_arguments: [described_class::GROUP_ID, 'up'],
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
