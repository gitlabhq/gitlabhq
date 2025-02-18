# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteMilestonesWithoutProjectOrGroup, migration: :gitlab_main, feature_category: :team_planning do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:milestones) { table(:milestones) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)

    milestones.create!(title: 'Milestone 1')
    milestones.create!(title: 'Milestone 2')
    milestones.create!(title: 'Milestone 3')
    milestones.create!(title: 'Milestone 4')
    milestones.create!(group_id: namespace.id, title: 'Milestone 5')
    milestones.create!(project_id: project.id, title: 'Milestone 6')
  end

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate!
      end.to make_queries_matching(
        /DELETE FROM "milestones".+WHERE \(group_id IS NULL AND project_id IS NULL\)/,
        2
      )
    end

    it 'deletes offending records records' do
      expect { migrate! }.to change { milestones.count }.from(6).to(2)
    end
  end
end
