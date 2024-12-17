# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy,
  '#next_batch', feature_category: :database do
  let(:batching_strategy) { described_class.new(connection: ActiveRecord::Base.connection) }
  let(:job_class) { Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) }
  let(:namespaces) { table(:namespaces) }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace1) { namespaces.create!(name: 'batchtest999', path: 'batch-test1', organization_id: organization.id) }
  let!(:namespace2) { namespaces.create!(name: 'batchtest2', path: 'batch-test2', organization_id: organization.id) }
  let!(:namespace3) { namespaces.create!(name: 'batchtest3', path: 'batch-test3', organization_id: organization.id) }
  let!(:namespace4) { namespaces.create!(name: 'batchtest4', path: 'batch-test4', organization_id: organization.id) }

  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchingStrategies::BaseStrategy }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace1.id, batch_size: 3, job_arguments: [], job_class: job_class)

      expect(batch_bounds).to eq([namespace1.id, namespace3.id])
    end
  end

  context 'when additional batches remain' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace2.id, batch_size: 3, job_arguments: [], job_class: job_class)

      expect(batch_bounds).to eq([namespace2.id, namespace4.id])
    end
  end

  context 'when on the final batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace4.id, batch_size: 3, job_arguments: [], job_class: job_class)

      expect(batch_bounds).to eq([namespace4.id, namespace4.id])
    end
  end

  context 'when no additional batches remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace4.id + 1, batch_size: 1, job_arguments: [], job_class: job_class)

      expect(batch_bounds).to be_nil
    end
  end

  context 'when job class supports batch scope DSL' do
    let(:job_class) do
      Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
        job_arguments :min_id
        scope_to ->(r) { r.where.not(type: 'Project').where('id >= ?', min_id) }
      end
    end

    it 'applies the additional scope' do
      expect(job_class).to receive(:generic_instance).and_call_original

      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace4.id, batch_size: 3, job_arguments: [1], job_class: job_class)

      expect(batch_bounds).to eq([namespace4.id, namespace4.id])
    end

    context 'when scope has a join which makes the column name ambiguous' do
      let(:job_class) do
        Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
          scope_to ->(r) { r.joins('LEFT JOIN namespaces as parents ON parents.id = namespaces.parent_id') }
        end
      end

      it 'executes the correct query' do
        expect(job_class).to receive(:generic_instance).and_call_original

        batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace4.id, batch_size: 3, job_arguments: [], job_class: job_class)

        expect(batch_bounds).to eq([namespace4.id, namespace4.id])
      end
    end
  end

  context 'when job class requires not to reset order' do
    let(:job_class) do
      Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
        scope_to ->(r) { r.order(:name) }

        def self.reset_order
          false
        end
      end
    end

    it 'does not reset order' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace1.id, batch_size: 3, job_arguments: [], job_class: job_class)

      expect(batch_bounds).to eq([namespace2.id, namespace4.id])
    end
  end
end
