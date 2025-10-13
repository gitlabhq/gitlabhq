# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BackgroundOperation::CronEnqueueWorker, feature_category: :database do
  let(:worker) { described_class.new }
  let(:job_class_name) { 'TestBackgroundJob' }
  let(:table_name) { 'projects' }
  let(:column_name) { 'id' }
  let(:job_arguments) { %w[arg1 arg2] }
  let(:options) do
    {
      'batch_size' => 100,
      'min_cursor' => [100]
    }
  end

  let(:args) do
    {
      'job_class_name' => job_class_name,
      'table_name' => table_name,
      'column_name' => column_name,
      'job_arguments' => job_arguments,
      'options' => options
    }
  end

  describe '#perform' do
    subject(:execution) { worker.perform(args) }

    it 'enqueues cell-local background operation using Queueable API' do
      expect(Gitlab::Database::BackgroundOperation::WorkerCellLocal)
        .to receive(:enqueue)
        .with(
          job_class_name,
          table_name,
          column_name,
          job_arguments: job_arguments,
          batch_size: 100,
          min_cursor: [100]
        )

      execution
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { args }
    end
  end
end
