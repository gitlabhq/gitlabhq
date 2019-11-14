# frozen_string_literal: true

require 'spec_helper'

describe Projects::HashedStorage::RollbackService do
  let(:project) { create(:project, :empty_repo, :wiki_repo) }
  let(:logger) { double }

  subject(:service) { described_class.new(project, project.disk_path, logger: logger) }

  describe '#execute' do
    context 'attachments rollback' do
      let(:attachments_service_class) { Projects::HashedStorage::RollbackAttachmentsService }
      let(:attachments_service) { attachments_service_class.new(project: project, old_disk_path: project.disk_path, logger: logger) }

      it 'delegates rollback to Projects::HashedStorage::RollbackAttachmentsService' do
        expect(service).to receive(:rollback_attachments_service).and_return(attachments_service)
        expect(attachments_service).to receive(:execute)

        service.execute
      end

      it 'does not delegate rollback if repository is in legacy storage already' do
        project.storage_version = nil
        expect(attachments_service_class).not_to receive(:new)

        service.execute
      end
    end

    context 'repository rollback' do
      let(:project) { create(:project, :empty_repo, :wiki_repo, storage_version: ::Project::HASHED_STORAGE_FEATURES[:repository]) }
      let(:repository_service_class) { Projects::HashedStorage::RollbackRepositoryService }
      let(:repository_service) { repository_service_class.new(project: project, old_disk_path: project.disk_path, logger: logger) }

      it 'delegates rollback to RollbackRepositoryService' do
        expect(service).to receive(:rollback_repository_service).and_return(repository_service)
        expect(repository_service).to receive(:execute)

        service.execute
      end

      it 'does not delegate rollback if repository is in legacy storage already' do
        project.storage_version = nil

        expect(repository_service_class).not_to receive(:new)

        service.execute
      end
    end
  end
end
