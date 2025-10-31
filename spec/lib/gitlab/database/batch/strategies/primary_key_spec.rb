# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Batch::Strategies::PrimaryKey, '#next_batch', feature_category: :database do
  include MigrationsHelpers

  let(:batching_strategy) { described_class.new(connection: ActiveRecord::Base.connection) }
  let(:job_class) do
    Class.new(Gitlab::BackgroundOperation::BaseOperationWorker) do
      cursor :id
    end
  end

  let(:namespaces) { table(:namespaces) }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace1) { namespaces.create!(name: 'batchtest999', path: 'batch-test1', organization_id: organization.id) }
  let!(:namespace2) { namespaces.create!(name: 'batchtest2', path: 'batch-test2', organization_id: organization.id) }
  let!(:namespace3) { namespaces.create!(name: 'batchtest3', path: 'batch-test3', organization_id: organization.id) }
  let!(:namespace4) { namespaces.create!(name: 'batchtest4', path: 'batch-test4', organization_id: organization.id) }

  it { expect(described_class).to be < Gitlab::Database::Batch::Strategies::BaseStrategy }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:namespaces, batch_min_value: [0], batch_size: 3,
        job_class: job_class)

      expect(batch_bounds).to match_array([[namespace1.id], [namespace3.id]])
    end
  end

  context 'when on the final batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:namespaces, batch_min_value: [namespace3.id], batch_size: 3,
        job_class: job_class)

      expect(batch_bounds).to match_array([[namespace4.id], [namespace4.id]])
    end
  end

  context 'when no additional batches remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(:namespaces, batch_min_value: [namespace4.id], batch_size: 1,
        job_class: job_class)

      expect(batch_bounds).to be_nil
    end
  end
end
