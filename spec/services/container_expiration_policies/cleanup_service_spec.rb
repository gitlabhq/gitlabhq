# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicies::CleanupService do
  let_it_be(:repository, reload: true) { create(:container_repository) }
  let_it_be(:project) { repository.project }

  let(:service) { described_class.new(repository) }

  describe '#execute' do
    subject { service.execute }

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
          expect(repository.expiration_policy_started_at).to eq(nil)
          expect(repository.expiration_policy_completed_at).not_to eq(nil)
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
            before_delete_size: 100
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
                cleanup_tags_service_before_delete_size: 100
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
        response = subject

        expect(response.success?).to eq(false)
      end
    end
  end
end
