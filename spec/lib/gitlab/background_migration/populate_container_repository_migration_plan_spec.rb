# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateContainerRepositoryMigrationPlan, schema: 20220316202640 do
  let!(:container_repositories) { table(:container_repositories) }
  let!(:projects) { table(:projects) }
  let!(:namespaces) { table(:namespaces) }
  let!(:gitlab_subscriptions) { table(:gitlab_subscriptions) }
  let!(:plans) { table(:plans) }
  let!(:namespace_statistics) { table(:namespace_statistics) }

  let!(:namepace1) { namespaces.create!(id: 1, type: 'Group', name: 'group1', path: 'group1', traversal_ids: [1]) }
  let!(:namepace2) { namespaces.create!(id: 2, type: 'Group', name: 'group2', path: 'group2', traversal_ids: [2]) }
  let!(:namepace3) { namespaces.create!(id: 3, type: 'Group', name: 'group3', path: 'group3', traversal_ids: [3]) }
  let!(:sub_namespace) { namespaces.create!(id: 4, type: 'Group', name: 'group3', path: 'group3', parent_id: 1, traversal_ids: [1, 4]) }
  let!(:plan1) { plans.create!(id: 1, name: 'plan1') }
  let!(:plan2) { plans.create!(id: 2, name: 'plan2') }
  let!(:gitlab_subscription1) { gitlab_subscriptions.create!(id: 1, namespace_id: 1, hosted_plan_id: 1) }
  let!(:gitlab_subscription2) { gitlab_subscriptions.create!(id: 2, namespace_id: 2, hosted_plan_id: 2) }
  let!(:project1) { projects.create!(id: 1, name: 'project1', path: 'project1', namespace_id: 4) }
  let!(:project2) { projects.create!(id: 2, name: 'project2', path: 'project2', namespace_id: 2) }
  let!(:project3) { projects.create!(id: 3, name: 'project3', path: 'project3', namespace_id: 3) }
  let!(:container_repository1) { container_repositories.create!(id: 1, name: 'cr1', project_id: 1) }
  let!(:container_repository2) { container_repositories.create!(id: 2, name: 'cr2', project_id: 2) }
  let!(:container_repository3) { container_repositories.create!(id: 3, name: 'cr3', project_id: 3) }

  let(:migration) { described_class.new }

  subject do
    migration.perform(1, 4)
  end

  it 'updates the migration_plan to match the actual plan', :aggregate_failures do
    expect(Gitlab::Database::BackgroundMigrationJob).to receive(:mark_all_as_succeeded)
      .with('PopulateContainerRepositoryMigrationPlan', [1, 4]).and_return(true)

    subject

    expect(container_repository1.reload.migration_plan).to eq('plan1')
    expect(container_repository2.reload.migration_plan).to eq('plan2')
    expect(container_repository3.reload.migration_plan).to eq(nil)
  end
end
