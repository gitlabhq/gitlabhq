# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicies::CleanupContainerRepositoryWorker do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:repository, refind: true) { create(:container_repository, :cleanup_scheduled, expiration_policy_started_at: 1.month.ago) }
  let_it_be(:other_repository, refind: true) { create(:container_repository, expiration_policy_started_at: 15.days.ago) }

  let(:project) { repository.project }
  let(:policy) { project.container_expiration_policy }
  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject { worker.perform_work }

    before do
      policy.update_column(:enabled, true)
    end

    shared_examples 'handling all repository conditions' do
      it 'sends the repository for cleaning' do
        service_response = cleanup_service_response(repository: repository)
        expect(ContainerExpirationPolicies::CleanupService)
          .to receive(:new).with(repository).and_return(double(execute: service_response))
        expect_log_extra_metadata(service_response: service_response)

        subject
      end

      context 'with unfinished cleanup' do
        it 'logs an unfinished cleanup' do
          service_response = cleanup_service_response(status: :unfinished, repository: repository)
          expect(ContainerExpirationPolicies::CleanupService)
            .to receive(:new).with(repository).and_return(double(execute: service_response))
          expect_log_extra_metadata(service_response: service_response, cleanup_status: :unfinished)

          subject
        end

        context 'with a truncated list of tags to delete' do
          it 'logs an unfinished cleanup' do
            service_response = cleanup_service_response(status: :unfinished, repository: repository, cleanup_tags_service_after_truncate_size: 10, cleanup_tags_service_before_delete_size: 5)
            expect(ContainerExpirationPolicies::CleanupService)
              .to receive(:new).with(repository).and_return(double(execute: service_response))
            expect_log_extra_metadata(service_response: service_response, cleanup_status: :unfinished, truncated: true)

            subject
          end
        end

        context 'the truncated log field' do
          where(:before_truncate_size, :after_truncate_size, :truncated) do
            100 | 100 | false
            100 | 80  | true
            nil | 100 | false
            100 | nil | false
            nil | nil | false
          end

          with_them do
            it 'is logged properly' do
              service_response = cleanup_service_response(status: :unfinished, repository: repository, cleanup_tags_service_after_truncate_size: after_truncate_size, cleanup_tags_service_before_truncate_size: before_truncate_size)
              expect(ContainerExpirationPolicies::CleanupService)
                .to receive(:new).with(repository).and_return(double(execute: service_response))
              expect_log_extra_metadata(service_response: service_response, cleanup_status: :unfinished, truncated: truncated)

              subject
            end
          end
        end
      end

      context 'with an erroneous cleanup' do
        it 'logs an error' do
          service_response = ServiceResponse.error(message: 'cleanup in an error')
          expect(ContainerExpirationPolicies::CleanupService)
            .to receive(:new).with(repository).and_return(double(execute: service_response))
          expect_log_extra_metadata(service_response: service_response, cleanup_status: :error)

          subject
        end
      end

      context 'with policy running shortly' do
        before do
          repository.cleanup_unfinished!
          policy.update_column(:next_run_at, 1.minute.from_now)
        end

        it 'skips the repository' do
          expect(ContainerExpirationPolicies::CleanupService).not_to receive(:new)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:container_repository_id, repository.id)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:project_id, repository.project.id)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_status, :skipped)
          expect { subject }.to change { ContainerRepository.waiting_for_cleanup.count }.from(1).to(0)

          expect(repository.reload.cleanup_unscheduled?).to be_truthy
        end
      end

      context 'with disabled policy' do
        before do
          policy.disable!
        end

        it 'skips the repository' do
          expect(ContainerExpirationPolicies::CleanupService).not_to receive(:new)

          expect { subject }
            .to not_change { ContainerRepository.waiting_for_cleanup.count }
            .and not_change { repository.reload.expiration_policy_cleanup_status }
        end
      end
    end

    context 'with repository in cleanup unscheduled state' do
      before do
        policy.update_column(:next_run_at, 5.minutes.ago)
      end

      it_behaves_like 'handling all repository conditions'
    end

    context 'with repository in cleanup unfinished state' do
      before do
        repository.cleanup_unfinished!
      end

      it_behaves_like 'handling all repository conditions'
    end

    context 'container repository selection' do
      where(:repository_cleanup_status, :repository_policy_status, :other_repository_cleanup_status, :other_repository_policy_status, :expected_selected_repository) do
        :unscheduled | :disabled     | :unscheduled | :disabled     | :none
        :unscheduled | :disabled     | :unscheduled | :runnable     | :other_repository
        :unscheduled | :disabled     | :unscheduled | :not_runnable | :none

        :unscheduled | :disabled     | :scheduled   | :disabled     | :none
        :unscheduled | :disabled     | :scheduled   | :runnable     | :other_repository
        :unscheduled | :disabled     | :scheduled   | :not_runnable | :none

        :unscheduled | :disabled     | :unfinished  | :disabled     | :none
        :unscheduled | :disabled     | :unfinished  | :runnable     | :other_repository
        :unscheduled | :disabled     | :unfinished  | :not_runnable | :other_repository

        :unscheduled | :disabled     | :ongoing     | :disabled     | :none
        :unscheduled | :disabled     | :ongoing     | :runnable     | :none
        :unscheduled | :disabled     | :ongoing     | :not_runnable | :none

        :unscheduled | :runnable     | :unscheduled | :disabled     | :repository
        :unscheduled | :runnable     | :unscheduled | :runnable     | :repository
        :unscheduled | :runnable     | :unscheduled | :not_runnable | :repository

        :unscheduled | :runnable     | :scheduled   | :disabled     | :repository
        :unscheduled | :runnable     | :scheduled   | :runnable     | :repository
        :unscheduled | :runnable     | :scheduled   | :not_runnable | :repository

        :unscheduled | :runnable     | :unfinished  | :disabled     | :repository
        :unscheduled | :runnable     | :unfinished  | :runnable     | :repository
        :unscheduled | :runnable     | :unfinished  | :not_runnable | :repository

        :unscheduled | :runnable     | :ongoing     | :disabled     | :repository
        :unscheduled | :runnable     | :ongoing     | :runnable     | :repository
        :unscheduled | :runnable     | :ongoing     | :not_runnable | :repository

        :scheduled   | :disabled     | :unscheduled | :disabled     | :none
        :scheduled   | :disabled     | :unscheduled | :runnable     | :other_repository
        :scheduled   | :disabled     | :unscheduled | :not_runnable | :none

        :scheduled   | :disabled     | :scheduled   | :disabled     | :none
        :scheduled   | :disabled     | :scheduled   | :runnable     | :other_repository
        :scheduled   | :disabled     | :scheduled   | :not_runnable | :none

        :scheduled   | :disabled     | :unfinished  | :disabled     | :none
        :scheduled   | :disabled     | :unfinished  | :runnable     | :other_repository
        :scheduled   | :disabled     | :unfinished  | :not_runnable | :other_repository

        :scheduled   | :disabled     | :ongoing     | :disabled     | :none
        :scheduled   | :disabled     | :ongoing     | :runnable     | :none
        :scheduled   | :disabled     | :ongoing     | :not_runnable | :none

        :scheduled   | :runnable     | :unscheduled | :disabled     | :repository
        :scheduled   | :runnable     | :unscheduled | :runnable     | :other_repository
        :scheduled   | :runnable     | :unscheduled | :not_runnable | :repository

        :scheduled   | :runnable     | :scheduled   | :disabled     | :repository
        :scheduled   | :runnable     | :scheduled   | :runnable     | :repository
        :scheduled   | :runnable     | :scheduled   | :not_runnable | :repository

        :scheduled   | :runnable     | :unfinished  | :disabled     | :repository
        :scheduled   | :runnable     | :unfinished  | :runnable     | :repository
        :scheduled   | :runnable     | :unfinished  | :not_runnable | :repository

        :scheduled   | :runnable     | :ongoing     | :disabled     | :repository
        :scheduled   | :runnable     | :ongoing     | :runnable     | :repository
        :scheduled   | :runnable     | :ongoing     | :not_runnable | :repository

        :scheduled   | :not_runnable | :unscheduled | :disabled     | :none
        :scheduled   | :not_runnable | :unscheduled | :runnable     | :other_repository
        :scheduled   | :not_runnable | :unscheduled | :not_runnable | :none

        :scheduled   | :not_runnable | :scheduled   | :disabled     | :none
        :scheduled   | :not_runnable | :scheduled   | :runnable     | :other_repository
        :scheduled   | :not_runnable | :scheduled   | :not_runnable | :none

        :scheduled   | :not_runnable | :unfinished  | :disabled     | :none
        :scheduled   | :not_runnable | :unfinished  | :runnable     | :other_repository
        :scheduled   | :not_runnable | :unfinished  | :not_runnable | :other_repository

        :scheduled   | :not_runnable | :ongoing     | :disabled     | :none
        :scheduled   | :not_runnable | :ongoing     | :runnable     | :none
        :scheduled   | :not_runnable | :ongoing     | :not_runnable | :none

        :unfinished  | :disabled     | :unscheduled | :disabled     | :none
        :unfinished  | :disabled     | :unscheduled | :runnable     | :other_repository
        :unfinished  | :disabled     | :unscheduled | :not_runnable | :none

        :unfinished  | :disabled     | :scheduled   | :disabled     | :none
        :unfinished  | :disabled     | :scheduled   | :runnable     | :other_repository
        :unfinished  | :disabled     | :scheduled   | :not_runnable | :none

        :unfinished  | :disabled     | :unfinished  | :disabled     | :none
        :unfinished  | :disabled     | :unfinished  | :runnable     | :other_repository
        :unfinished  | :disabled     | :unfinished  | :not_runnable | :other_repository

        :unfinished  | :disabled     | :ongoing     | :disabled     | :none
        :unfinished  | :disabled     | :ongoing     | :runnable     | :none
        :unfinished  | :disabled     | :ongoing     | :not_runnable | :none

        :unfinished  | :runnable     | :unscheduled | :disabled     | :repository
        :unfinished  | :runnable     | :unscheduled | :runnable     | :other_repository
        :unfinished  | :runnable     | :unscheduled | :not_runnable | :repository

        :unfinished  | :runnable     | :scheduled   | :disabled     | :repository
        :unfinished  | :runnable     | :scheduled   | :runnable     | :other_repository
        :unfinished  | :runnable     | :scheduled   | :not_runnable | :repository

        :unfinished  | :runnable     | :unfinished  | :disabled     | :repository
        :unfinished  | :runnable     | :unfinished  | :runnable     | :repository
        :unfinished  | :runnable     | :unfinished  | :not_runnable | :repository

        :unfinished  | :runnable     | :ongoing     | :disabled     | :repository
        :unfinished  | :runnable     | :ongoing     | :runnable     | :repository
        :unfinished  | :runnable     | :ongoing     | :not_runnable | :repository

        :unfinished  | :not_runnable | :unscheduled | :disabled     | :repository
        :unfinished  | :not_runnable | :unscheduled | :runnable     | :other_repository
        :unfinished  | :not_runnable | :unscheduled | :not_runnable | :repository

        :unfinished  | :not_runnable | :scheduled   | :disabled     | :repository
        :unfinished  | :not_runnable | :scheduled   | :runnable     | :other_repository
        :unfinished  | :not_runnable | :scheduled   | :not_runnable | :repository

        :unfinished  | :not_runnable | :unfinished  | :disabled     | :repository
        :unfinished  | :not_runnable | :unfinished  | :runnable     | :repository
        :unfinished  | :not_runnable | :unfinished  | :not_runnable | :repository

        :unfinished  | :not_runnable | :ongoing     | :disabled     | :repository
        :unfinished  | :not_runnable | :ongoing     | :runnable     | :repository
        :unfinished  | :not_runnable | :ongoing     | :not_runnable | :repository

        :ongoing     | :disabled     | :unscheduled | :disabled     | :none
        :ongoing     | :disabled     | :unscheduled | :runnable     | :other_repository
        :ongoing     | :disabled     | :unscheduled | :not_runnable | :none

        :ongoing     | :disabled     | :scheduled   | :disabled     | :none
        :ongoing     | :disabled     | :scheduled   | :runnable     | :other_repository
        :ongoing     | :disabled     | :scheduled   | :not_runnable | :none

        :ongoing     | :disabled     | :unfinished  | :disabled     | :none
        :ongoing     | :disabled     | :unfinished  | :runnable     | :other_repository
        :ongoing     | :disabled     | :unfinished  | :not_runnable | :other_repository

        :ongoing     | :disabled     | :ongoing     | :disabled     | :none
        :ongoing     | :disabled     | :ongoing     | :runnable     | :none
        :ongoing     | :disabled     | :ongoing     | :not_runnable | :none

        :ongoing     | :runnable     | :unscheduled | :disabled     | :none
        :ongoing     | :runnable     | :unscheduled | :runnable     | :other_repository
        :ongoing     | :runnable     | :unscheduled | :not_runnable | :none

        :ongoing     | :runnable     | :scheduled   | :disabled     | :none
        :ongoing     | :runnable     | :scheduled   | :runnable     | :other_repository
        :ongoing     | :runnable     | :scheduled   | :not_runnable | :none

        :ongoing     | :runnable     | :unfinished  | :disabled     | :none
        :ongoing     | :runnable     | :unfinished  | :runnable     | :other_repository
        :ongoing     | :runnable     | :unfinished  | :not_runnable | :other_repository

        :ongoing     | :runnable     | :ongoing     | :disabled     | :none
        :ongoing     | :runnable     | :ongoing     | :runnable     | :none
        :ongoing     | :runnable     | :ongoing     | :not_runnable | :none

        :ongoing     | :not_runnable | :unscheduled | :disabled     | :none
        :ongoing     | :not_runnable | :unscheduled | :runnable     | :other_repository
        :ongoing     | :not_runnable | :unscheduled | :not_runnable | :none

        :ongoing     | :not_runnable | :scheduled   | :disabled     | :none
        :ongoing     | :not_runnable | :scheduled   | :runnable     | :other_repository
        :ongoing     | :not_runnable | :scheduled   | :not_runnable | :none

        :ongoing     | :not_runnable | :unfinished  | :disabled     | :none
        :ongoing     | :not_runnable | :unfinished  | :runnable     | :other_repository
        :ongoing     | :not_runnable | :unfinished  | :not_runnable | :other_repository

        :ongoing     | :not_runnable | :ongoing     | :disabled     | :none
        :ongoing     | :not_runnable | :ongoing     | :runnable     | :none
        :ongoing     | :not_runnable | :ongoing     | :not_runnable | :none
      end

      with_them do
        before do
          update_container_repository(repository, repository_cleanup_status, repository_policy_status)
          update_container_repository(other_repository, other_repository_cleanup_status, other_repository_policy_status)
        end

        subject { worker.send(:container_repository) }

        if params[:expected_selected_repository] == :none
          it 'does not select any repository' do
            expect(subject).to eq(nil)
          end
        else
          it 'does select a repository' do
            selected_repository = expected_selected_repository == :repository ? repository : other_repository

            expect(subject).to eq(selected_repository)
          end
        end

        def update_container_repository(container_repository, cleanup_status, policy_status)
          container_repository.update_column(:expiration_policy_cleanup_status, "cleanup_#{cleanup_status}")

          policy = container_repository.project.container_expiration_policy

          case policy_status
          when :disabled
            policy.update!(enabled: false)
          when :runnable
            policy.update!(enabled: true)
            policy.update_column(:next_run_at, 5.minutes.ago)
          when :not_runnable
            policy.update!(enabled: true)
            policy.update_column(:next_run_at, 5.minutes.from_now)
          end
        end
      end
    end

    context 'with another repository in cleanup unfinished state' do
      let_it_be(:another_repository) { create(:container_repository, :cleanup_unfinished) }

      before do
        policy.update_column(:next_run_at, 5.minutes.ago)
      end

      it 'process the cleanup scheduled repository first' do
        service_response = cleanup_service_response(repository: repository)
        expect(ContainerExpirationPolicies::CleanupService)
          .to receive(:new).with(repository).and_return(double(execute: service_response))
        expect_log_extra_metadata(service_response: service_response)

        subject
      end
    end

    def cleanup_service_response(status: :finished, repository:, cleanup_tags_service_original_size: 100, cleanup_tags_service_before_truncate_size: 80, cleanup_tags_service_after_truncate_size: 80, cleanup_tags_service_before_delete_size: 50, cleanup_tags_service_deleted_size: 50)
      ServiceResponse.success(
        message: "cleanup #{status}",
        payload: {
          cleanup_status: status,
          container_repository_id: repository.id,
          cleanup_tags_service_original_size: cleanup_tags_service_original_size,
          cleanup_tags_service_before_truncate_size: cleanup_tags_service_before_truncate_size,
          cleanup_tags_service_after_truncate_size: cleanup_tags_service_after_truncate_size,
          cleanup_tags_service_before_delete_size: cleanup_tags_service_before_delete_size
        }.compact
      )
    end

    def expect_log_extra_metadata(service_response:, cleanup_status: :finished, truncated: false)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:container_repository_id, repository.id)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:project_id, repository.project.id)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_status, cleanup_status)

      %i[cleanup_tags_service_original_size cleanup_tags_service_before_truncate_size cleanup_tags_service_after_truncate_size cleanup_tags_service_before_delete_size cleanup_tags_service_deleted_size].each do |field|
        value = service_response.payload[field]
        expect(worker).to receive(:log_extra_metadata_on_done).with(field, value) unless value.nil?
      end
      expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_tags_service_truncated, truncated)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:running_jobs_count, 0)

      if service_response.error?
        expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_error_message, service_response.message)
      end
    end
  end

  describe '#remaining_work_count' do
    let_it_be(:disabled_repository) { create(:container_repository, :cleanup_scheduled) }

    let(:capacity) { 10 }

    subject { worker.remaining_work_count }

    before do
      stub_application_setting(container_registry_expiration_policies_worker_capacity: capacity)

      ContainerExpirationPolicy.update_all(enabled: true)
      repository.project.container_expiration_policy.update_column(:next_run_at, 5.minutes.ago)
      disabled_repository.project.container_expiration_policy.update_column(:enabled, false)
    end

    context 'counts and capacity' do
      where(:scheduled_count, :unfinished_count, :capacity, :expected_count) do
        2 | 2 | 10 | 4
        2 | 0 | 10 | 2
        0 | 2 | 10 | 2
        4 | 2 | 2  | 4
        4 | 0 | 2  | 4
        0 | 4 | 2  | 4
      end

      with_them do
        before do
          allow(worker).to receive(:cleanup_scheduled_count).and_return(scheduled_count)
          allow(worker).to receive(:cleanup_unfinished_count).and_return(unfinished_count)
        end

        it { is_expected.to eq(expected_count) }
      end
    end

    context 'with container repositories waiting for cleanup' do
      let_it_be(:unfinished_repositories) { create_list(:container_repository, 2, :cleanup_unfinished) }

      it { is_expected.to eq(3) }
    end

    context 'with no container repositories waiting for cleanup' do
      before do
        repository.cleanup_ongoing!
        policy.update_column(:next_run_at, 5.minutes.from_now)
      end

      it { is_expected.to eq(0) }
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
end
