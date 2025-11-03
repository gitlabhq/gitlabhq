# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillPartitionedProjectDailyStatistics, migration: :gitlab_main, feature_category: :source_code_management do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace_1) { table(:namespaces).create!(name: 'name1', path: 'path1', organization_id: organization.id) }
  let(:namespace_2) { table(:namespaces).create!(name: 'name2', path: 'path2', organization_id: organization.id) }
  let(:project_1) do
    table(:projects).create!(
      namespace_id: namespace_1.id,
      project_namespace_id: namespace_1.id,
      organization_id: organization.id
    )
  end

  let(:project_2) do
    table(:projects).create!(
      namespace_id: namespace_2.id,
      project_namespace_id: namespace_2.id,
      organization_id: organization.id
    )
  end

  let(:project_1_id) { project_1.id }
  let(:project_2_id) { project_2.id }

  describe '#up' do
    before do
      connection.execute(<<~SQL)
        INSERT INTO project_daily_statistics (id, project_id, fetch_count, date)
        VALUES
          (1001, #{project_1_id}, 10, '2025-08-01'),
          (1002, #{project_1_id}, 20, '2025-08-10'),
          (1003, #{project_2_id}, 20, '2025-08-11'),
          (1004, #{project_1_id}, 30, '2025-08-15')
      SQL
    end

    context 'when records exist' do
      before do
        # Override the START_DATE constant to test if it can find the right min date.
        stub_const("#{described_class}::START_DATE", Date.new(2025, 8, 10))
      end

      it 'finds the correct min_id and enqueues the migration' do
        expect(migration).to receive(:enqueue_partitioning_data_migration)
          .with('project_daily_statistics', 'BackfillPartitionedProjectDailyStatistics', batch_min_value: 1002)

        migration.up
      end
    end

    context 'when no records exist within 40 days of the start date' do
      before do
        # Override the START_DATE constant for this test
        stub_const("#{described_class}::START_DATE", Date.new(2025, 2, 1))
      end

      it 'does not enqueues the migration' do
        expect(migration).not_to receive(:enqueue_partitioning_data_migration)

        migration.up
      end
    end
  end
end
