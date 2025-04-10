# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillListsShardingKey, feature_category: :team_planning do
  let(:lists) { table(:lists) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:fake_namespace) do
    table(:namespaces).create!(name: "fake_namespace", path: "fake_namespace", organization_id: organization.id)
  end

  let(:board1) { table(:boards).create!(group_id: namespace.id) }
  let(:board2) { table(:boards).create!(project_id: project.id) }
  let(:migration) do
    start_id, end_id = lists.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :lists,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  before do
    [board1, board2].each do |board|
      # Using another namespace as we already have an INVALID NOT NULL constraint and FK
      2.times { lists.create!(board_id: board.id, group_id: fake_namespace.id) }
    end

    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  subject(:migrate) { migration.perform }

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate
      end.to make_queries_matching(/UPDATE\s+"lists"/, 2)
    end

    it 'sets group_id or project_id in every record' do
      expect { migrate }.to change {
        lists.order(:id).pluck(:group_id, :project_id)
      }.from(
        Array.new(4) { [fake_namespace.id, nil] }
      ).to(
        [
          [namespace.id, nil],
          [namespace.id, nil],
          [nil, project.id],
          [nil, project.id]
        ]
      )
    end
  end
end
