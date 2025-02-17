# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillShardingKeyOnBoardLabels, migration: :gitlab_main, feature_category: :team_planning do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:board1) { table(:boards).create!(group_id: namespace.id) }
  let(:board2) { table(:boards).create!(project_id: project.id) }
  let(:label1) { table(:labels).create!(title: 'label1', project_id: project.id) }
  let(:label2) { table(:labels).create!(title: 'label2', project_id: project.id) }

  before do
    [board1, board2].each do |board|
      [label1, label2].each { |user| table(:board_labels).create!(label_id: user.id, board_id: board.id) }
    end

    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate!
      end.to make_queries_matching(/UPDATE\s+"board_labels"/, 2)
    end

    it 'sets group_id or project_id in every record' do
      expect { migrate! }.to change {
        table(:board_labels).order(:id).pluck(:group_id, :project_id)
      }.from(
        Array.new(4) { [nil, nil] }
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
