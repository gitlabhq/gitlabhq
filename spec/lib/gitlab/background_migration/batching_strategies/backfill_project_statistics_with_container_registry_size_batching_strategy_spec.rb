# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::BackfillProjectStatisticsWithContainerRegistrySizeBatchingStrategy, '#next_batch' do # rubocop:disable Layout/LineLength
  let(:batching_strategy) { described_class.new(connection: ActiveRecord::Base.connection) }
  let(:namespace) { table(:namespaces) }
  let(:project) { table(:projects) }
  let(:container_repositories) { table(:container_repositories) }

  let!(:group) do
    namespace.create!(
      name: 'namespace1', type: 'Group', path: 'space1'
    )
  end

  let!(:proj_namespace1) do
    namespace.create!(
      name: 'proj1', path: 'proj1', type: 'Project', parent_id: group.id
    )
  end

  let!(:proj_namespace2) do
    namespace.create!(
      name: 'proj2', path: 'proj2', type: 'Project', parent_id: group.id
    )
  end

  let!(:proj_namespace3) do
    namespace.create!(
      name: 'proj3', path: 'proj3', type: 'Project', parent_id: group.id
    )
  end

  let!(:proj1) do
    project.create!(
      name: 'proj1', path: 'proj1', namespace_id: group.id, project_namespace_id: proj_namespace1.id
    )
  end

  let!(:proj2) do
    project.create!(
      name: 'proj2', path: 'proj2', namespace_id: group.id, project_namespace_id: proj_namespace2.id
    )
  end

  let!(:proj3) do
    project.create!(
      name: 'proj3', path: 'proj3', namespace_id: group.id, project_namespace_id: proj_namespace3.id
    )
  end

  let!(:con1) do
    container_repositories.create!(
      project_id: proj1.id,
      name: "ContReg_#{proj1.id}:1",
      migration_state: 'import_done',
      created_at: Date.new(2022, 01, 20)
    )
  end

  let!(:con2) do
    container_repositories.create!(
      project_id: proj1.id,
      name: "ContReg_#{proj1.id}:2",
      migration_state: 'import_done',
      created_at: Date.new(2022, 01, 20)
    )
  end

  let!(:con3) do
    container_repositories.create!(
      project_id: proj2.id,
      name: "ContReg_#{proj2.id}:1",
      migration_state: 'import_done',
      created_at: Date.new(2022, 01, 20)
    )
  end

  let!(:con4) do
    container_repositories.create!(
      project_id: proj3.id,
      name: "ContReg_#{proj3.id}:1",
      migration_state: 'default',
      created_at: Date.new(2022, 02, 20)
    )
  end

  let!(:con5) do
    container_repositories.create!(
      project_id: proj3.id,
      name: "ContReg_#{proj3.id}:2",
      migration_state: 'default',
      created_at: Date.new(2022, 02, 20)
    )
  end

  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(
        :container_repositories,
        :project_id,
        batch_min_value: con1.project_id,
        batch_size: 3,
        job_arguments: []
      )
      expect(batch_bounds).to eq([con1.project_id, con4.project_id])
    end
  end

  context 'when additional batches remain' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(
        :container_repositories,
        :project_id,
        batch_min_value: con3.project_id,
        batch_size: 3,
        job_arguments: []
      )

      expect(batch_bounds).to eq([con3.project_id, con5.project_id])
    end
  end

  context 'when no additional batches remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(:container_repositories,
        :project_id,
        batch_min_value: con5.project_id + 1,
        batch_size: 1, job_arguments: []
      )

      expect(batch_bounds).to be_nil
    end
  end
end
