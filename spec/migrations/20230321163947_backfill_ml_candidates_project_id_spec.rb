# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillMlCandidatesProjectId, feature_category: :mlops do
  let(:migration) { described_class.new }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:ml_experiments) { table(:ml_experiments) }
  let(:ml_candidates) { table(:ml_candidates) }

  let(:namespace1) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:namespace2) { namespaces.create!(name: 'bar', path: 'bar') }
  let(:project1) { projects.create!(project_namespace_id: namespace1.id, namespace_id: namespace1.id) }
  let(:project2) { projects.create!(project_namespace_id: namespace2.id, namespace_id: namespace2.id) }
  let(:experiment1) { ml_experiments.create!(project_id: project1.id, iid: 1, name: 'experiment') }
  let(:experiment2) { ml_experiments.create!(project_id: project2.id, iid: 1, name: 'experiment') }
  let!(:candidate1) do
    ml_candidates.create!(experiment_id: experiment1.id, project_id: nil, eid: SecureRandom.uuid)
  end

  let!(:candidate2) do
    ml_candidates.create!(experiment_id: experiment2.id, project_id: nil, eid: SecureRandom.uuid)
  end

  let!(:candidate3) do
    ml_candidates.create!(experiment_id: experiment1.id, project_id: project1.id, eid: SecureRandom.uuid)
  end

  describe '#up' do
    it 'sets the correct project_id with idempotency', :aggregate_failures do
      migration.up

      expect(candidate1.reload.project_id).to be(project1.id)
      expect(candidate2.reload.project_id).to be(project2.id)
      # in case we have candidates added between the column addition and the migration
      expect(candidate3.reload.project_id).to be(project1.id)

      migration.down
      migration.up

      expect(candidate1.reload.project_id).to be(project1.id)
      expect(candidate2.reload.project_id).to be(project2.id)
      expect(candidate3.reload.project_id).to be(project1.id)
    end
  end
end
