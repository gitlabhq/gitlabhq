# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryCleanupWorker, feature_category: :source_code_management do
  let(:project) { create(:project, bfg_object_map: fixture_file_upload('spec/fixtures/bfg_object_map.txt')) }
  let(:user) { create(:user) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'executes the cleanup service and sends a success notification', :aggregate_failures do
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
      project.destroy!

      expect { worker.perform(project.id, user.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises an error if the user cannot be found' do
      user.destroy!

      expect { worker.perform(project.id, user.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#perform_failure' do
    before do
      project.set_repository_read_only!
    end

    it 'cleans up the attempt and sends a failure notification', :aggregate_failures do
      expect_next_instance_of(NotificationService) do |service|
        expect(service).to receive(:repository_cleanup_failure).with(project, user, 'Error')
      end

      expect { worker.perform_failure(project.id, user.id, 'Error') }
        .to change { project.reload.repository_read_only? }.from(true).to(false)

      expect(project.bfg_object_map).not_to be_exist
    end

    context 'when the project no longer exists' do
      before do
        project.destroy!
      end

      it 'does not send a failure notification', :aggregate_failures do
        expect(NotificationService).not_to receive(:new)

        expect { worker.perform_failure(project.id, user.id, 'Error') }.not_to raise_error
      end
    end

    context 'when the user no longer exists' do
      before do
        user.destroy!
      end

      it 'makes the repository writable without a failure notification', :aggregate_failures do
        expect(NotificationService).not_to receive(:new)

        expect { worker.perform_failure(project.id, user.id, 'Error') }
          .to change { project.reload.repository_read_only? }.from(true).to(false)
      end
    end

    context 'when removing the BFG object map fails' do
      let(:removal_error) { IOError.new('remove failed') }

      before do
        allow(Project).to receive(:find_by_id).with(project.id).and_return(project)
        allow(project.bfg_object_map).to receive(:remove!).and_raise(removal_error)
      end

      it 'tracks the removal error, unlocks the repository and sends the original failure notification',
        :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(removal_error, project_id: project.id)
        expect_next_instance_of(NotificationService) do |service|
          expect(service).to receive(:repository_cleanup_failure).with(project, user, 'Error')
        end

        worker.perform_failure(project.id, user.id, 'Error')

        expect(project.reload.repository_read_only?).to be(false)
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => [project.id, user.id], 'error_message' => 'Error' } }

    it 'passes the job error to perform_failure' do
      expect_next_instance_of(described_class) do |worker|
        expect(worker).to receive(:perform_failure).with(project.id, user.id, 'Error')
      end

      described_class.sidekiq_retries_exhausted_block.call(job, ActiveRecord::RecordNotFound.new)
    end
  end

  describe '.sidekiq_interruptions_exhausted' do
    let(:job) { { 'args' => [project.id, user.id], 'error_message' => 'Stale error from an earlier attempt' } }

    it 'passes the max interruptions message to perform_failure' do
      expect_next_instance_of(described_class) do |worker|
        expect(worker).to receive(:perform_failure)
          .with(project.id, user.id, described_class::MAX_INTERRUPTIONS_ERROR_MESSAGE)
      end

      described_class.interruptions_exhausted_block.call(job)
    end
  end
end
