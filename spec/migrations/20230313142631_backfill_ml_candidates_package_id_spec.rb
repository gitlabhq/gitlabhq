# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillMlCandidatesPackageId, feature_category: :mlops do
  let(:migration) { described_class.new }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:ml_experiments) { table(:ml_experiments) }
  let(:ml_candidates) { table(:ml_candidates) }
  let(:packages_packages) { table(:packages_packages) }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:project) { projects.create!(project_namespace_id: namespace.id, namespace_id: namespace.id) }
  let(:experiment) { ml_experiments.create!(project_id: project.id, iid: 1, name: 'experiment') }
  let!(:candidate1) { ml_candidates.create!(experiment_id: experiment.id, iid: SecureRandom.uuid) }
  let!(:candidate2) { ml_candidates.create!(experiment_id: experiment.id, iid: SecureRandom.uuid) }
  let!(:package1) do
    packages_packages.create!(
      project_id: project.id,
      name: "ml_candidate_#{candidate1.id}",
      version: "-",
      package_type: 7
    )
  end

  let!(:package2) do
    packages_packages.create!(
      project_id: project.id,
      name: "ml_candidate_1000",
      version: "-",
      package_type: 7)
  end

  let!(:package3) do
    packages_packages.create!(
      project_id: project.id,
      name: "ml_candidate_abcde",
      version: "-",
      package_type: 7
    )
  end

  describe '#up' do
    it 'sets the correct package_ids with idempotency', :aggregate_failures do
      migration.up

      expect(candidate1.reload.package_id).to be(package1.id)
      expect(candidate2.reload.package_id).to be(nil)

      migration.down
      migration.up

      expect(candidate1.reload.package_id).to be(package1.id)
      expect(candidate2.reload.package_id).to be(nil)
    end
  end
end
