# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteBoardsWithoutProjectAndGroup, migration: :gitlab_main, feature_category: :team_planning do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:boards) { table(:boards) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)

    boards.create!
    boards.create!
    boards.create!
    boards.create!
    boards.create!(group_id: namespace.id)
  end

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate!
      end.to make_queries_matching(
        /DELETE FROM "boards".+WHERE \(group_id IS NULL AND project_id IS NULL\)/,
        2
      )
    end

    it 'deletes offending records records' do
      expect { migrate! }.to change { boards.count }.from(5).to(1)
    end
  end
end
