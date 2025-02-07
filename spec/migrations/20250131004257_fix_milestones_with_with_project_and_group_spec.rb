# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixMilestonesWithWithProjectAndGroup, migration: :gitlab_main, feature_category: :team_planning do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:milestones) { table(:milestones) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:milestone1) { milestones.create!(group_id: namespace.id, project_id: project.id, title: 'Milestone 1') }
  let!(:milestone2) { milestones.create!(group_id: namespace.id, project_id: project.id, title: 'Milestone 2') }
  let!(:milestone3) { milestones.create!(group_id: namespace.id, project_id: project.id, title: 'Milestone 3') }
  let!(:milestone4) { milestones.create!(group_id: namespace.id, project_id: project.id, title: 'Milestone 4') }
  let!(:milestone5) { milestones.create!(group_id: namespace.id, title: 'Milestone 5') }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate!
      end.to make_queries_matching(
        /UPDATE\s+"milestones".+WHERE \(group_id IS NOT NULL AND project_id IS NOT NULL\)/,
        2
      )
    end

    it 'removes group_id from offending records' do
      expect { migrate! }.to change {
        [milestone1, milestone2, milestone3, milestone4].each(&:reload).pluck(:project_id, :group_id)
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
        not_change { milestone5.reload.group_id }.from(namespace.id)
      )
    end
  end
end
