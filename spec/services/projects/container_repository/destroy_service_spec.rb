# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::DestroyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }

  subject { described_class.new(project, user) }

  before do
    stub_container_registry_config(enabled: true)
  end

  context 'when user does not have access to registry' do
    let!(:repository) { create(:container_repository, :root, project: project) }

    it 'does not delete a repository' do
      expect { subject.execute(repository) }.not_to change { ContainerRepository.count }
    end
  end

  context 'when user has access to registry' do
    before do
      project.add_developer(user)
    end

    context 'when root container repository exists' do
      let!(:repository) { create(:container_repository, :root, project: project) }

      before do
        stub_container_registry_tags(repository: :any, tags: %w[latest stable])
      end

      it 'deletes the repository' do
        expect_cleanup_tags_service_with(container_repository: repository, return_status: :success)
        expect { subject.execute(repository) }.to change { ContainerRepository.count }.by(-1)
      end

      it 'sends disable_timeout = true as part of the params as default' do
        expect_cleanup_tags_service_with(container_repository: repository, return_status: :success, disable_timeout: true)
        expect { subject.execute(repository) }.to change { ContainerRepository.count }.by(-1)
      end

      it 'sends disable_timeout = false as part of the params if it is set to false' do
        expect_cleanup_tags_service_with(container_repository: repository, return_status: :success, disable_timeout: false)
        expect { subject.execute(repository, disable_timeout: false) }.to change { ContainerRepository.count }.by(-1)
      end

      context 'when deleting the tags fails' do
        it 'sets status as deleted_failed' do
          expect_cleanup_tags_service_with(container_repository: repository, return_status: :error)
          allow(Gitlab::AppLogger).to receive(:error).and_call_original

          subject.execute(repository)

          expect(repository).to be_delete_failed
          expect(Gitlab::AppLogger).to have_received(:error)
          .with("Container repository with ID: #{repository.id} and path: #{repository.path} failed with message: error in deleting tags")
        end
      end

      context 'when destroying the repository fails' do
        it 'sets status as deleted_failed' do
          expect_cleanup_tags_service_with(container_repository: repository, return_status: :success)
          allow(repository).to receive(:destroy).and_return(false)
          allow(repository.errors).to receive(:full_messages).and_return(['Error 1', 'Error 2'])
          allow(Gitlab::AppLogger).to receive(:error).and_call_original

          subject.execute(repository)

          expect(repository).to be_delete_failed
          expect(Gitlab::AppLogger).to have_received(:error)
          .with("Container repository with ID: #{repository.id} and path: #{repository.path} failed with message: Error 1. Error 2")
        end
      end

      def expect_cleanup_tags_service_with(container_repository:, return_status:, disable_timeout: true)
        delete_tags_service = instance_double(Projects::ContainerRepository::CleanupTagsService)

        expect(Projects::ContainerRepository::CleanupTagsService).to receive(:new).with(
          container_repository: container_repository,
          params: described_class::CLEANUP_TAGS_SERVICE_PARAMS.merge('disable_timeout' => disable_timeout)
        ).and_return(delete_tags_service)

        expect(delete_tags_service).to receive(:execute).and_return(status: return_status)
      end
    end
  end
end
