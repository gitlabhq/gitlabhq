# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicies::CleanupService do
  let_it_be(:repository, reload: true) { create(:container_repository, expiration_policy_started_at: 30.minutes.ago) }
  let_it_be(:project) { repository.project }

  let(:service) { described_class.new(repository) }

  describe '#execute' do
    let(:policy) { repository.project.container_expiration_policy }

    subject { service.execute }

    before do
      policy.update!(enabled: true)
      policy.update_column(:next_run_at, 5.minutes.ago)
    end

    context 'with a successful cleanup tags service execution' do
      let(:cleanup_tags_service_params) { project.container_expiration_policy.policy_params.merge('container_expiration_policy' => true) }
      let(:cleanup_tags_service) { instance_double(Projects::ContainerRepository::CleanupTagsService) }

      it 'completely clean up the repository' do
        expect(Projects::ContainerRepository::CleanupTagsService)
          .to receive(:new).with(project, nil, cleanup_tags_service_params).and_return(cleanup_tags_service)
        expect(cleanup_tags_service).to receive(:execute).with(repository).and_return(status: :success)

        response = subject

        aggregate_failures "checking the response and container repositories" do
          expect(response.success?).to eq(true)
          expect(response.payload).to include(cleanup_status: :finished, container_repository_id: repository.id)
          expect(ContainerRepository.waiting_for_cleanup.count).to eq(0)
          expect(repository.reload.cleanup_unscheduled?).to be_truthy
          expect(repository.expiration_policy_completed_at).not_to eq(nil)
          expect(repository.expiration_policy_started_at).not_to eq(nil)
        end
      end
    end

    context 'without a successful cleanup tags service execution' do
      let(:cleanup_tags_service_response) { { status: :error, message: 'timeout' } }

      before do
        expect(Projects::ContainerRepository::CleanupTagsService)
          .to receive(:new).and_return(double(execute: cleanup_tags_service_response))
      end

      it 'partially clean up the repository' do
        response = subject

        aggregate_failures "checking the response and container repositories" do
          expect(response.success?).to eq(true)
          expect(response.payload).to include(cleanup_status: :unfinished, container_repository_id: repository.id)
          expect(ContainerRepository.waiting_for_cleanup.count).to eq(1)
          expect(repository.reload.cleanup_unfinished?).to be_truthy
          expect(repository.expiration_policy_started_at).not_to eq(nil)
          expect(repository.expiration_policy_completed_at).to eq(nil)
        end
      end

      context 'with a truncated cleanup tags service response' do
        let(:cleanup_tags_service_response) do
          {
            status: :error,
            original_size: 1000,
            before_truncate_size: 800,
            after_truncate_size: 200,
            before_delete_size: 100,
            deleted_size: 100
          }
        end

        it 'partially clean up the repository' do
          response = subject

          aggregate_failures "checking the response and container repositories" do
            expect(response.success?).to eq(true)
            expect(response.payload)
              .to include(
                cleanup_status: :unfinished,
                container_repository_id: repository.id,
                cleanup_tags_service_original_size: 1000,
                cleanup_tags_service_before_truncate_size: 800,
                cleanup_tags_service_after_truncate_size: 200,
                cleanup_tags_service_before_delete_size: 100,
                cleanup_tags_service_deleted_size: 100
              )
            expect(ContainerRepository.waiting_for_cleanup.count).to eq(1)
            expect(repository.reload.cleanup_unfinished?).to be_truthy
            expect(repository.expiration_policy_started_at).not_to eq(nil)
            expect(repository.expiration_policy_completed_at).to eq(nil)
          end
        end
      end
    end

    context 'with no repository' do
      let(:service) { described_class.new(nil) }

      it 'returns an error response' do
        expect(subject.success?).to eq(false)
        expect(subject.message).to eq('no repository')
      end
    end

    context 'with an invalid policy' do
      let(:policy) { repository.project.container_expiration_policy }

      before do
        policy.name_regex = nil
        policy.enabled = true
        repository.expiration_policy_cleanup_status = :cleanup_ongoing
      end

      it 'returns an error response' do
        expect { subject }.to change { repository.expiration_policy_cleanup_status }.from('cleanup_ongoing').to('cleanup_unscheduled')
        expect(subject.success?).to eq(false)
        expect(subject.message).to eq('invalid policy')
        expect(policy).not_to be_enabled
      end
    end

    context 'with a network error' do
      before do
        expect(Projects::ContainerRepository::CleanupTagsService)
          .to receive(:new).and_raise(Faraday::TimeoutError)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Faraday::TimeoutError)

        expect(ContainerRepository.waiting_for_cleanup.count).to eq(1)
        expect(repository.reload.cleanup_unfinished?).to be_truthy
        expect(repository.expiration_policy_started_at).not_to eq(nil)
        expect(repository.expiration_policy_completed_at).to eq(nil)
      end
    end

    context 'next run scheduling' do
      let_it_be_with_reload(:repository2) { create(:container_repository, project: project) }
      let_it_be_with_reload(:repository3) { create(:container_repository, project: project) }

      before do
        cleanup_tags_service = instance_double(Projects::ContainerRepository::CleanupTagsService)
        allow(Projects::ContainerRepository::CleanupTagsService)
          .to receive(:new).and_return(cleanup_tags_service)
        allow(cleanup_tags_service).to receive(:execute).and_return(status: :success)
      end

      shared_examples 'not scheduling the next run' do
        it 'does not scheduled the next run' do
          expect(policy).not_to receive(:schedule_next_run!)

          expect { subject }.not_to change { policy.reload.next_run_at }
        end
      end

      shared_examples 'scheduling the next run' do
        it 'schedules the next run' do
          expect(policy).to receive(:schedule_next_run!).and_call_original

          expect { subject }.to change { policy.reload.next_run_at }
        end
      end

      context 'with cleanups started_at before policy next_run_at' do
        before do
          ContainerRepository.update_all(expiration_policy_started_at: 10.minutes.ago)
        end

        it_behaves_like 'not scheduling the next run'
      end

      context 'with cleanups started_at around policy next_run_at' do
        before do
          repository3.update!(expiration_policy_started_at: policy.next_run_at + 10.minutes.ago)
        end

        it_behaves_like 'not scheduling the next run'
      end

      context 'with only the current repository started_at before the policy next_run_at' do
        before do
          repository2.update!(expiration_policy_started_at: policy.next_run_at + 10.minutes)
          repository3.update!(expiration_policy_started_at: policy.next_run_at + 12.minutes)
        end

        it_behaves_like 'scheduling the next run'
      end

      context 'with cleanups started_at after policy next_run_at' do
        before do
          ContainerRepository.update_all(expiration_policy_started_at: policy.next_run_at + 10.minutes)
        end

        it_behaves_like 'scheduling the next run'
      end

      context 'with a future policy next_run_at' do
        before do
          policy.update_column(:next_run_at, 5.minutes.from_now)
        end

        it_behaves_like 'not scheduling the next run'
      end
    end
  end
end
