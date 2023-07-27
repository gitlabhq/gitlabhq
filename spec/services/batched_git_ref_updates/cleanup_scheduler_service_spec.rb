# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BatchedGitRefUpdates::CleanupSchedulerService, feature_category: :gitaly do
  let(:service) { described_class.new }

  describe '#execute' do
    before do
      BatchedGitRefUpdates::Deletion.create!(project_id: 123, ref: 'ref1')
      BatchedGitRefUpdates::Deletion.create!(project_id: 123, ref: 'ref2')
      BatchedGitRefUpdates::Deletion.create!(project_id: 456, ref: 'ref3')
      BatchedGitRefUpdates::Deletion.create!(project_id: 789, ref: 'ref4', status: :processed)
    end

    it 'schedules ProjectCleanupWorker for each project in pending BatchedGitRefUpdates::Deletion' do
      project_ids = []
      expect(BatchedGitRefUpdates::ProjectCleanupWorker)
        .to receive(:bulk_perform_async_with_contexts) do |deletions, arguments_proc:, context_proc:| # rubocop:disable Lint/UnusedBlockArgument
        project_ids += deletions.map(&arguments_proc)
      end

      service.execute

      expect(project_ids).to contain_exactly(123, 456)
    end

    it 'returns stats' do
      stats = service.execute

      expect(stats).to eq({
        total_projects: 2
      })
    end

    it 'acquires a lock to avoid running duplicate instances' do
      expect(service).to receive(:in_lock) # Mock and don't yield
        .with(described_class.name, retries: 0, ttl: described_class::LOCK_TIMEOUT)
      expect(BatchedGitRefUpdates::ProjectCleanupWorker).not_to receive(:bulk_perform_async_with_contexts)

      service.execute
    end

    it 'limits to MAX_PROJECTS before it stops' do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      stub_const("#{described_class}::MAX_PROJECTS", 1)

      stats = service.execute

      expect(stats).to eq({
        total_projects: 1
      })
    end
  end
end
