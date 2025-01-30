# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixBoardsWithProjectAndGroup, migration: :gitlab_main, feature_category: :team_planning do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:board1) { table(:boards).create!(group_id: namespace.id, project_id: project.id) }
  let!(:board2) { table(:boards).create!(group_id: namespace.id, project_id: project.id) }
  let!(:board3) { table(:boards).create!(group_id: namespace.id, project_id: project.id) }
  let!(:board4) { table(:boards).create!(group_id: namespace.id, project_id: project.id) }
  let!(:board5) { table(:boards).create!(group_id: namespace.id) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate!
      end.to make_queries_matching(/UPDATE\s+"boards"/, 2)
    end

    it 'removes group_id from offending records' do
      expect { migrate! }.to change {
        [board1, board2, board3, board4].each(&:reload).pluck(:project_id, :group_id)
      }.from(
        Array.new(4) { [project.id, namespace.id] }
      ).to(
        [
          [project.id, nil],
          [project.id, nil],
          [project.id, nil],
          [project.id, nil]
        ]
      ).and(
        not_change { board5.reload.group_id }.from(namespace.id)
      )
    end
  end
end
