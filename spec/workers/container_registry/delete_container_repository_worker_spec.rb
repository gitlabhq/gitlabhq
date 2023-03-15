# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::DeleteContainerRepositoryWorker, :aggregate_failures, feature_category: :container_registry do
  let_it_be_with_reload(:container_repository) { create(:container_repository) }
  let_it_be(:second_container_repository) { create(:container_repository) }

  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work }

    context 'with no work to do - no container repositories pending deletion' do
      it 'will not delete any container repository' do
        expect(::Projects::ContainerRepository::CleanupTagsService).not_to receive(:new)

        expect { perform_work }.to not_change { ContainerRepository.count }
      end
    end

    context 'with work to do' do
      let(:tags_count) { 0 }
      let(:cleanup_tags_service_response) { { status: :success, original_size: 100, deleted_size: 0 } }
      let(:cleanup_tags_service_double) do
        instance_double('Projects::ContainerRepository::CleanupTagsService', execute: cleanup_tags_service_response)
      end

      before do
        container_repository.delete_scheduled!
        allow(Projects::ContainerRepository::CleanupTagsService)
          .to receive(:new)
                .with(container_repository: container_repository, params: described_class::CLEANUP_TAGS_SERVICE_PARAMS)
                .and_return(cleanup_tags_service_double)
      end

      it 'picks and destroys the delete scheduled container repository' do
        expect_next_pending_destruction_container_repository do |repo|
          expect_logs_on(repo, tags_size_before_delete: 100, deleted_tags_size: 0)
          expect(repo).to receive(:destroy!).and_call_original
        end
        perform_work
        expect(ContainerRepository.all).to contain_exactly(second_container_repository)
      end

      context 'with an error during the tags cleanup' do
        let(:cleanup_tags_service_response) { { status: :error, original_size: 100, deleted_size: 0 } }

        it 'does not delete the container repository' do
          expect_next_pending_destruction_container_repository do |repo|
            expect_logs_on(repo, tags_size_before_delete: 100, deleted_tags_size: 0)
            expect(repo).to receive(:set_delete_scheduled_status).and_call_original
            expect(repo).not_to receive(:destroy!)
          end
          expect { perform_work }.to not_change(ContainerRepository, :count)
                                       .and not_change { container_repository.reload.status }
          expect(container_repository.delete_started_at).to eq(nil)
        end
      end

      context 'with an error during the destroy' do
        it 'does not delete the container repository' do
          expect_next_pending_destruction_container_repository do |repo|
            expect_logs_on(repo, tags_size_before_delete: 100, deleted_tags_size: 0)
            expect(repo).to receive(:destroy!).and_raise('Error!')
            expect(repo).to receive(:set_delete_scheduled_status).and_call_original
          end

          expect(::Gitlab::ErrorTracking).to receive(:log_exception)
                                               .with(instance_of(RuntimeError), class: described_class.name)
          expect { perform_work }.to not_change(ContainerRepository, :count)
                                       .and not_change { container_repository.reload.status }
          expect(container_repository.delete_started_at).to eq(nil)
        end
      end

      context 'with tags left to destroy' do
        let(:tags_count) { 10 }

        it 'does not delete the container repository' do
          expect_next_pending_destruction_container_repository do |repo|
            expect(repo).not_to receive(:destroy!)
            expect(repo).to receive(:set_delete_scheduled_status).and_call_original
          end

          expect { perform_work }.to not_change(ContainerRepository, :count)
                                       .and not_change { container_repository.reload.status }
          expect(container_repository.delete_started_at).to eq(nil)
        end
      end

      context 'with no tags on the container repository' do
        let(:tags_count) { 0 }
        let(:cleanup_tags_service_response) { { status: :success, original_size: 0, deleted_size: 0 } }

        it 'picks and destroys the delete scheduled container repository' do
          expect_next_pending_destruction_container_repository do |repo|
            expect_logs_on(repo, tags_size_before_delete: 0, deleted_tags_size: 0)
            expect(repo).to receive(:destroy!).and_call_original
          end
          perform_work
          expect(ContainerRepository.all).to contain_exactly(second_container_repository)
        end
      end

      def expect_next_pending_destruction_container_repository
        original_method = ContainerRepository.method(:next_pending_destruction)
        expect(ContainerRepository).to receive(:next_pending_destruction).with(order_by: nil) do
          original_method.call(order_by: nil).tap do |repo|
            allow(repo).to receive(:tags_count).and_return(tags_count)
            expect(repo).to receive(:set_delete_ongoing_status).and_call_original
            yield repo
          end
        end
      end

      def expect_logs_on(container_repository, tags_size_before_delete:, deleted_tags_size:)
        payload = {
          project_id: container_repository.project.id,
          container_repository_id: container_repository.id,
          container_repository_path: container_repository.path,
          tags_size_before_delete: tags_size_before_delete,
          deleted_tags_size: deleted_tags_size
        }
        expect(worker.logger).to receive(:info).with(worker.structured_payload(payload))
                                   .and_call_original
      end
    end
  end

  describe '#max_running_jobs' do
    subject { worker.max_running_jobs }

    it { is_expected.to eq(described_class::MAX_CAPACITY) }
  end

  describe '#remaining_work_count' do
    let_it_be(:delete_scheduled_container_repositories) do
      create_list(:container_repository, described_class::MAX_CAPACITY + 2, :status_delete_scheduled)
    end

    subject { worker.remaining_work_count }

    it { is_expected.to eq(described_class::MAX_CAPACITY + 1) }
  end
end
