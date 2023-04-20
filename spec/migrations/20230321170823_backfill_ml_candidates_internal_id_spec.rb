# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillMlCandidatesInternalId, feature_category: :mlops do
  let(:migration) { described_class.new }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:ml_experiments) { table(:ml_experiments) }
  let(:ml_candidates) { table(:ml_candidates) }

  let(:namespace1) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:namespace2) { namespaces.create!(name: 'bar', path: 'bar') }
  let(:project1) { projects.create!(project_namespace_id: namespace1.id, namespace_id: namespace1.id) }
  let(:project2) { projects.create!(project_namespace_id: namespace2.id, namespace_id: namespace2.id) }
  let(:experiment1) { ml_experiments.create!(project_id: project1.id, iid: 1, name: 'experiment1') }
  let(:experiment2) { ml_experiments.create!(project_id: project1.id, iid: 2, name: 'experiment2') }
  let(:experiment3) { ml_experiments.create!(project_id: project2.id, iid: 1, name: 'experiment3') }

  let!(:candidate1) do
    ml_candidates.create!(experiment_id: experiment1.id, project_id: project1.id, eid: SecureRandom.uuid)
  end

  let!(:candidate2) do
    ml_candidates.create!(experiment_id: experiment2.id, project_id: project1.id, eid: SecureRandom.uuid)
  end

  let!(:candidate3) do
    ml_candidates.create!(experiment_id: experiment1.id, project_id: project1.id, eid: SecureRandom.uuid)
  end

  let!(:candidate4) do
    ml_candidates.create!(experiment_id: experiment1.id, project_id: project1.id, internal_id: 1,
      eid: SecureRandom.uuid)
  end

  let!(:candidate5) do
    ml_candidates.create!(experiment_id: experiment3.id, project_id: project2.id, eid: SecureRandom.uuid)
  end

  describe '#up' do
    it 'sets the correct project_id with idempotency', :aggregate_failures do
      migration.up

      expect(candidate4.reload.internal_id).to be(1) # candidate 4 already has an internal_id
      expect(candidate1.reload.internal_id).to be(2)
      expect(candidate2.reload.internal_id).to be(3)
      expect(candidate3.reload.internal_id).to be(4)
      expect(candidate5.reload.internal_id).to be(1) # candidate 5 is a different project

      migration.down
      migration.up

      expect(candidate4.reload.internal_id).to be(1)
      expect(candidate1.reload.internal_id).to be(2)
      expect(candidate2.reload.internal_id).to be(3)
      expect(candidate3.reload.internal_id).to be(4)
      expect(candidate5.reload.internal_id).to be(1)
    end
  end
end
