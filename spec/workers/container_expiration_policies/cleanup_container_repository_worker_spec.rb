# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicies::CleanupContainerRepositoryWorker do
  let_it_be(:repository, reload: true) { create(:container_repository, :cleanup_scheduled) }
  let_it_be(:project) { repository.project }
  let_it_be(:policy) { project.container_expiration_policy }
  let_it_be(:other_repository) { create(:container_repository) }

  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject { worker.perform_work }

    before do
      policy.update_column(:enabled, true)
    end

    RSpec.shared_examples 'handling all repository conditions' do
      it 'sends the repository for cleaning' do
        expect(ContainerExpirationPolicies::CleanupService)
          .to receive(:new).with(repository).and_return(double(execute: cleanup_service_response(repository: repository)))
        expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_status, :finished)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:container_repository_id, repository.id)

        subject
      end

      context 'with unfinished cleanup' do
        it 'logs an unfinished cleanup' do
          expect(ContainerExpirationPolicies::CleanupService)
            .to receive(:new).with(repository).and_return(double(execute: cleanup_service_response(status: :unfinished, repository: repository)))
          expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_status, :unfinished)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:container_repository_id, repository.id)

          subject
        end
      end

      context 'with policy running shortly' do
        before do
          repository.project
                    .container_expiration_policy
                    .update_column(:next_run_at, 1.minute.from_now)
        end

        it 'skips the repository' do
          expect(ContainerExpirationPolicies::CleanupService).not_to receive(:new)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:container_repository_id, repository.id)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_status, :skipped)

          expect { subject }.to change { ContainerRepository.waiting_for_cleanup.count }.from(1).to(0)
          expect(repository.reload.cleanup_unscheduled?).to be_truthy
        end
      end

      context 'with disabled policy' do
        before do
          repository.project
                    .container_expiration_policy
                    .disable!
        end

        it 'skips the repository' do
          expect(ContainerExpirationPolicies::CleanupService).not_to receive(:new)

          expect { subject }.to change { ContainerRepository.waiting_for_cleanup.count }.from(1).to(0)
          expect(repository.reload.cleanup_unscheduled?).to be_truthy
        end
      end
    end

    context 'with repository in cleanup scheduled state' do
      it_behaves_like 'handling all repository conditions'
    end

    context 'with repository in cleanup unfinished state' do
      before do
        repository.cleanup_unfinished!
      end

      it_behaves_like 'handling all repository conditions'
    end

    context 'with another repository in cleanup unfinished state' do
      let_it_be(:another_repository) { create(:container_repository, :cleanup_unfinished) }

      it 'process the cleanup scheduled repository first' do
        expect(ContainerExpirationPolicies::CleanupService)
          .to receive(:new).with(repository).and_return(double(execute: cleanup_service_response(repository: repository)))
        expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_status, :finished)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:container_repository_id, repository.id)

        subject
      end
    end

    context 'with multiple repositories in cleanup unfinished state' do
      let_it_be(:repository2) { create(:container_repository, :cleanup_unfinished, expiration_policy_started_at: 20.minutes.ago) }
      let_it_be(:repository3) { create(:container_repository, :cleanup_unfinished, expiration_policy_started_at: 10.minutes.ago) }

      before do
        repository.update!(expiration_policy_cleanup_status: :cleanup_unfinished, expiration_policy_started_at: 30.minutes.ago)
      end

      it 'process the repository with the oldest expiration_policy_started_at' do
        expect(ContainerExpirationPolicies::CleanupService)
          .to receive(:new).with(repository).and_return(double(execute: cleanup_service_response(repository: repository)))
        expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_status, :finished)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:container_repository_id, repository.id)

        subject
      end
    end

    context 'with repository in cleanup ongoing state' do
      before do
        repository.cleanup_ongoing!
      end

      it 'does not process it' do
        expect(Projects::ContainerRepository::CleanupTagsService).not_to receive(:new)

        expect { subject }.not_to change { ContainerRepository.waiting_for_cleanup.count }
        expect(repository.cleanup_ongoing?).to be_truthy
      end
    end

    context 'with no repository in any cleanup state' do
      before do
        repository.cleanup_unscheduled!
      end

      it 'does not process it' do
        expect(Projects::ContainerRepository::CleanupTagsService).not_to receive(:new)

        expect { subject }.not_to change { ContainerRepository.waiting_for_cleanup.count }
        expect(repository.cleanup_unscheduled?).to be_truthy
      end
    end

    context 'with no container repository waiting' do
      before do
        repository.destroy!
      end

      it 'does not execute the cleanup tags service' do
        expect(Projects::ContainerRepository::CleanupTagsService).not_to receive(:new)

        expect { subject }.not_to change { ContainerRepository.waiting_for_cleanup.count }
      end
    end

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(container_registry_expiration_policies_throttling: false)
      end

      it 'is a no-op' do
        expect(Projects::ContainerRepository::CleanupTagsService).not_to receive(:new)

        expect { subject }.not_to change { ContainerRepository.waiting_for_cleanup.count }
      end
    end

    def cleanup_service_response(status: :finished, repository:)
      ServiceResponse.success(message: "cleanup #{status}", payload: { cleanup_status: status, container_repository_id: repository.id })
    end
  end

  describe '#remaining_work_count' do
    subject { worker.remaining_work_count }

    context 'with container repositoires waiting for cleanup' do
      let_it_be(:unfinished_repositories) { create_list(:container_repository, 2, :cleanup_unfinished) }

      it { is_expected.to eq(3) }

      it 'logs the work count' do
        expect_log_info(
          cleanup_scheduled_count: 1,
          cleanup_unfinished_count: 2,
          cleanup_total_count: 3
        )

        subject
      end
    end

    context 'with no container repositories waiting for cleanup' do
      before do
        repository.cleanup_ongoing!
      end

      it { is_expected.to eq(0) }

      it 'logs 0 work count' do
        expect_log_info(
          cleanup_scheduled_count: 0,
          cleanup_unfinished_count: 0,
          cleanup_total_count: 0
        )

        subject
      end
    end
  end

  describe '#max_running_jobs' do
    let(:capacity) { 50 }

    subject { worker.max_running_jobs }

    before do
      stub_application_setting(container_registry_expiration_policies_worker_capacity: capacity)
    end

    it { is_expected.to eq(capacity) }

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(container_registry_expiration_policies_throttling: false)
      end

      it { is_expected.to eq(0) }
    end
  end

  def expect_log_info(structure)
    expect(worker.logger)
      .to receive(:info).with(worker.structured_payload(structure))
  end
end
