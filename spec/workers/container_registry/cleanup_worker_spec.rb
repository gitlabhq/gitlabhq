# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::CleanupWorker, :aggregate_failures, feature_category: :container_registry do
  let(:worker) { described_class.new }

  describe '#perform' do
    let_it_be_with_reload(:container_repository) { create(:container_repository) }

    subject(:perform) { worker.perform }

    context 'with no delete scheduled container repositories' do
      it "doesn't enqueue delete container repository jobs" do
        expect(ContainerRegistry::DeleteContainerRepositoryWorker).not_to receive(:perform_with_capacity)

        perform
      end
    end

    context 'with delete scheduled container repositories' do
      before do
        container_repository.delete_scheduled!
      end

      it 'enqueues delete container repository jobs' do
        expect(ContainerRegistry::DeleteContainerRepositoryWorker).to receive(:perform_with_capacity)

        perform
      end
    end

    context 'with stale delete ongoing container repositories' do
      let(:delete_started_at) { (described_class::STALE_DELETE_THRESHOLD + 5.minutes).ago }

      before do
        container_repository.update!(status: :delete_ongoing, delete_started_at: delete_started_at)
      end

      it 'resets them and enqueue delete container repository jobs' do
        expect(ContainerRegistry::DeleteContainerRepositoryWorker).to receive(:perform_with_capacity)

        expect { perform }
          .to change { container_repository.reload.status }.from('delete_ongoing').to('delete_scheduled')
                .and change { container_repository.reload.delete_started_at }.to(nil)
      end
    end

    context 'for counts logging' do
      let_it_be(:delete_started_at) { (described_class::STALE_DELETE_THRESHOLD + 5.minutes).ago }
      let_it_be(:stale_delete_container_repository) do
        create(:container_repository, :status_delete_ongoing, delete_started_at: delete_started_at)
      end

      before do
        container_repository.delete_scheduled!
      end

      it 'logs the counts' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:delete_scheduled_container_repositories_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:stale_delete_container_repositories_count, 1)

        perform
      end
    end
  end
end
