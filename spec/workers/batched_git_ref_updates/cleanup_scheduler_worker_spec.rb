# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BatchedGitRefUpdates::CleanupSchedulerWorker, feature_category: :gitaly do
  let(:stats) { { total_projects: 456 } }
  let(:service) { instance_double(BatchedGitRefUpdates::CleanupSchedulerService, execute: stats) }
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow(BatchedGitRefUpdates::CleanupSchedulerService).to receive(:new).and_return(service)
    end

    it 'delegates to CleanupSchedulerService' do
      expect(service).to receive(:execute)

      worker.perform
    end

    it 'logs stats' do
      worker.perform

      expect(worker.logging_extras).to eq({
        "extra.batched_git_ref_updates_cleanup_scheduler_worker.stats" => { total_projects: 456 }
      })
    end
  end

  it_behaves_like 'an idempotent worker'
end
