# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BatchedGitRefUpdates::ProjectCleanupWorker, feature_category: :gitaly do
  let(:stats) { { total_deletes: 456 } }
  let(:service) { instance_double(BatchedGitRefUpdates::ProjectCleanupService, execute: stats) }
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow(BatchedGitRefUpdates::ProjectCleanupService).to receive(:new).with(123).and_return(service)
    end

    it 'delegates to ProjectCleanupService' do
      expect(service).to receive(:execute)

      worker.perform(123)
    end

    it 'logs stats' do
      worker.perform(123)

      expect(worker.logging_extras).to eq({
        "extra.batched_git_ref_updates_project_cleanup_worker.stats" => { total_deletes: 456 }
      })
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [123] }
  end
end
