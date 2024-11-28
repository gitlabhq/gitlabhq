# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::RecalculateAutoStopWorker, feature_category: :environment_management do
  let_it_be(:job) { create(:ci_build) }

  let(:job_id) { job.id }

  subject(:perform) { described_class.new.perform(job_id) }

  it 'executes Environments::RecalculateAutoStopService' do
    expect_next_instance_of(Environments::RecalculateAutoStopService, job) do |service|
      expect(service).to receive(:execute)
    end

    perform
  end

  context 'when a partition_id is specified' do
    subject(:perform) { described_class.new.perform(job_id, { 'partition_id' => job.partition_id }) }

    it 'uses the partition_id to find the job' do
      expect_next_instance_of(Environments::RecalculateAutoStopService, job) do |service|
        expect(service).to receive(:execute)
      end

      recorder = ActiveRecord::QueryRecorder.new { perform }

      expect(recorder.count).to eq(1)
      expect(recorder.log.first).to match(/^SELECT "#{job.class.table_name}".*"partition_id" = #{job.partition_id}/)
    end
  end

  context 'when the job no longer exists' do
    let(:job_id) { non_existing_record_id }

    it 'does nothing' do
      expect(Environments::RecalculateAutoStopService).not_to receive(:new)

      perform
    end
  end
end
