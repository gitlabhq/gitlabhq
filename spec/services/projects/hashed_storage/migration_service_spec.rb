# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HashedStorage::MigrationService, feature_category: :groups_and_projects do
  let(:project) { create(:project, :empty_repo, :wiki_repo, :legacy_storage) }
  let(:logger) { double }
  let!(:project_attachment) { build(:file_uploader, container: project) }
  let(:project_hashed_path) { Storage::Hashed.new(project).disk_path }
  let(:project_legacy_path) { Storage::LegacyProject.new(project).disk_path }
  let(:wiki_hashed_path) { "#{project_hashed_path}.wiki" }
  let(:wiki_legacy_path) { "#{project_legacy_path}.wiki" }

  subject(:service) { described_class.new(project, project.full_path, logger: logger) }

  describe '#execute' do
    context 'attachments migration' do
      let(:project) { create(:project, :empty_repo, :wiki_repo, storage_version: ::Project::HASHED_STORAGE_FEATURES[:repository]) }

      let(:attachments_service) do
        Projects::HashedStorage::MigrateAttachmentsService.new(
          project: project,
          old_disk_path: project.full_path,
          logger: logger
        )
      end

      it 'does not delegate migration if attachments are already migrated' do
        project.storage_version = ::Project::LATEST_STORAGE_VERSION
        expect(Projects::HashedStorage::MigrateAttachmentsService).not_to receive(:new)

        service.execute
      end

      it 'migrates legacy attachments to hashed storage' do
        legacy_attachments_path = FileUploader.absolute_base_dir(project)
        hashed_project = project.dup.tap { |p| p.id = project.id }
        hashed_project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:attachments]
        hashed_attachments_path = FileUploader.absolute_base_dir(hashed_project)

        expect(logger).to receive(:info).with(/Project attachments moved from '#{legacy_attachments_path}' to '#{hashed_attachments_path}'/)

        expect { service.execute }.to change { project.storage_version }.from(1).to(2)
      end
    end
  end
end
