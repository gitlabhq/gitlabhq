# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::BackfillProjectNamespacePerGroupBatchingStrategy, '#next_batch', :migration, schema: 20220326161803 do
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:background_migrations) { table(:batched_background_migrations) }

  let!(:namespace1) { namespaces.create!(name: 'batchtest1', type: 'Group', path: 'batch-test1') }
  let!(:namespace2) { namespaces.create!(name: 'batchtest2', type: 'Group', parent_id: namespace1.id, path: 'batch-test2') }
  let!(:namespace3) { namespaces.create!(name: 'batchtest3', type: 'Group', parent_id: namespace2.id, path: 'batch-test3') }

  let!(:project1) { projects.create!(name: 'project1', path: 'project1', namespace_id: namespace1.id, visibility_level: 20) }
  let!(:project2) { projects.create!(name: 'project2', path: 'project2', namespace_id: namespace2.id, visibility_level: 20) }
  let!(:project3) { projects.create!(name: 'project3', path: 'project3', namespace_id: namespace3.id, visibility_level: 20) }
  let!(:project4) { projects.create!(name: 'project4', path: 'project4', namespace_id: namespace3.id, visibility_level: 20) }
  let!(:batching_strategy) { described_class.new(connection: ActiveRecord::Base.connection) }

  let(:job_arguments) { [namespace1.id, 'up'] }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:projects, :id, batch_min_value: project1.id, batch_size: 3, job_arguments: job_arguments)

      expect(batch_bounds).to match_array([project1.id, project3.id])
    end
  end

  context 'when additional batches remain' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:projects, :id, batch_min_value: project2.id, batch_size: 3, job_arguments: job_arguments)

      expect(batch_bounds).to match_array([project2.id, project4.id])
    end
  end

  context 'when on the final batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:projects, :id, batch_min_value: project4.id, batch_size: 3, job_arguments: job_arguments)

      expect(batch_bounds).to match_array([project4.id, project4.id])
    end
  end

  context 'when no additional batches remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(:projects, :id, batch_min_value: project4.id + 1, batch_size: 1, job_arguments: job_arguments)

      expect(batch_bounds).to be_nil
    end
  end
end
