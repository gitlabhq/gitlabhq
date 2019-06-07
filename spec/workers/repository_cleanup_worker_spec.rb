# frozen_string_literal: true

require 'spec_helper'

describe RepositoryCleanupWorker do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'executes the cleanup service and sends a success notification' do
      expect_next_instance_of(Projects::CleanupService) do |service|
        expect(service.project).to eq(project)
        expect(service.current_user).to eq(user)

        expect(service).to receive(:execute)
      end

      expect_next_instance_of(NotificationService) do |service|
        expect(service).to receive(:repository_cleanup_success).with(project, user)
      end

      worker.perform(project.id, user.id)
    end

    it 'raises an error if the project cannot be found' do
      project.destroy

      expect { worker.perform(project.id, user.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises an error if the user cannot be found' do
      user.destroy

      expect { worker.perform(project.id, user.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#sidekiq_retries_exhausted' do
    let(:job) { { 'args' => [project.id, user.id], 'error_message' => 'Error' } }

    it 'does not send a failure notification for a RecordNotFound error' do
      expect(NotificationService).not_to receive(:new)

      described_class.sidekiq_retries_exhausted_block.call(job, ActiveRecord::RecordNotFound.new)
    end

    it 'sends a failure notification' do
      expect_next_instance_of(NotificationService) do |service|
        expect(service).to receive(:repository_cleanup_failure).with(project, user, 'Error')
      end

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)
    end
  end
end
