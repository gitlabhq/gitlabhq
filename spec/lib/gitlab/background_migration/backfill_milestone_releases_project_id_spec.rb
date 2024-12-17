# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs -- This uses a factory to build projects
RSpec.describe Gitlab::BackgroundMigration::BackfillMilestoneReleasesProjectId, feature_category: :release_orchestration do
  let(:groups_table) { table(:namespaces) { |t| t.primary_key = :id } }
  let(:projects_table) { table(:projects) { |t| t.primary_key = :id } }
  let(:releases_table) { table(:releases) { |t| t.primary_key = :id } }
  let(:milestone_releases_table) { table(:milestone_releases) { |t| t.primary_key = :milestone_id } }

  let!(:group) { create(:group) }
  let!(:project1) { create(:project, :repository, :public, namespace: group) }

  let!(:release_1) { releases_table.create!(id: 100, project_id: project1.id, released_at: 3.days.ago, tag: 'v1.1') }
  let!(:release_2) { releases_table.create!(id: 101, project_id: project1.id, released_at: 2.days.ago, tag: 'v1.2') }
  let!(:release_3) { releases_table.create!(id: 102, project_id: project1.id, released_at: 1.day.ago, tag: 'v1.3') }
  let!(:release_4) { releases_table.create!(id: 103, project_id: project1.id, released_at: 4.days.ago, tag: 'v1.0') }

  let!(:milestone_release_1) do
    milestone_releases_table.create!(milestone_id: 1, release_id: release_1.id, project_id: nil)
  end

  let!(:milestone_release_2) do
    milestone_releases_table.create!(milestone_id: 2, release_id: release_2.id, project_id: nil)
  end

  let!(:milestone_release_3) do
    milestone_releases_table.create!(milestone_id: 3, release_id: release_3.id, project_id: nil)
  end

  let!(:milestone_release_4) do
    milestone_releases_table.create!(milestone_id: 4, release_id: release_4.id, project_id: project1.id)
  end

  let(:migration_attrs) do
    {
      start_id: milestone_releases_table.minimum(:milestone_id),
      end_id: milestone_releases_table.maximum(:milestone_id),
      batch_table: :milestone_releases,
      batch_column: :milestone_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }
  let(:connection) { ActiveRecord::Base.connection }

  around do |example|
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE milestone_releases DISABLE TRIGGER ALL;
      SQL

      example.run

      connection.execute(<<~SQL)
        ALTER TABLE milestone_releases ENABLE TRIGGER ALL;
      SQL
    end
  end

  describe '#perform' do
    before do
      milestone_release_1.update!(release_id: release_1.id)
      milestone_release_2.update!(release_id: release_2.id)
      milestone_release_3.update!(release_id: release_3.id)
    end

    it 'backfills milestone_releases.project_id correctly for relevant records' do
      expect { migration.perform }
        .to change { milestone_release_1.reload.project_id }.from(nil).to(project1.id)
        .and change { milestone_release_2.reload.project_id }.from(nil).to(project1.id)
        .and change { milestone_release_3.reload.project_id }.from(nil).to(project1.id)
    end

    it 'does not update milestone releases with pre-existing project_id' do
      expect { migration.perform }
        .not_to change { milestone_release_4.reload.project_id }
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
