# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::ExportService do
  describe '#execute' do
    let!(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:shared) { project.import_export_shared }
    let!(:after_export_strategy) { Gitlab::ImportExport::AfterExportStrategies::DownloadNotificationStrategy.new }

    subject(:service) { described_class.new(project, user) }

    before do
      project.add_maintainer(user)
    end

    it 'saves the version' do
      expect(Gitlab::ImportExport::VersionSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'saves the avatar' do
      expect(Gitlab::ImportExport::AvatarSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'saves the models' do
      expect(Gitlab::ImportExport::Project::TreeSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'saves the uploads' do
      expect(Gitlab::ImportExport::UploadsSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'saves the repo' do
      # This spec errors when run against the EE codebase as there will be a third repository
      # saved (the EE-specific design repository).
      #
      # Instead, skip this test when run within EE. There is a spec for the EE-specific design repo
      # in the corresponding EE spec.
      skip if Gitlab.ee?

      # once for the normal repo, once for the wiki repo, and once for the design repo
      expect(Gitlab::ImportExport::RepoSaver).to receive(:new).exactly(3).times.and_call_original

      service.execute
    end

    it 'saves the wiki repo' do
      expect(Gitlab::ImportExport::WikiRepoSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'saves the design repo' do
      expect(Gitlab::ImportExport::DesignRepoSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'saves the lfs objects' do
      expect(Gitlab::ImportExport::LfsSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'saves the snippets' do
      expect_next_instance_of(Gitlab::ImportExport::SnippetsRepoSaver) do |instance|
        expect(instance).to receive(:save).and_call_original
      end

      service.execute
    end

    context 'when all saver services succeed' do
      before do
        allow(service).to receive(:save_services).and_return(true)
      end

      it 'saves the project in the file system' do
        expect(Gitlab::ImportExport::Saver).to receive(:save).with(exportable: project, shared: shared)

        service.execute
      end

      it 'calls the after export strategy' do
        expect(after_export_strategy).to receive(:execute)

        service.execute(after_export_strategy)
      end

      context 'when after export strategy fails' do
        before do
          allow(after_export_strategy).to receive(:execute).and_return(false)
        end

        after do
          service.execute(after_export_strategy)
        end

        it 'removes the remaining exported data' do
          allow(shared).to receive(:archive_path).and_return('whatever')
          allow(FileUtils).to receive(:rm_rf)

          expect(FileUtils).to receive(:rm_rf).with(shared.archive_path)
        end

        it 'notifies the user' do
          expect_next_instance_of(NotificationService) do |instance|
            expect(instance).to receive(:project_not_exported)
          end
        end

        it 'notifies logger' do
          expect(service.instance_variable_get(:@logger)).to receive(:error)
        end
      end
    end

    context 'when saving services fail' do
      before do
        allow(service).to receive(:save_exporters).and_return(false)
      end

      after do
        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
      end

      it 'removes the remaining exported data' do
        allow(shared).to receive(:archive_path).and_return('whatever')
        allow(FileUtils).to receive(:rm_rf)

        expect(FileUtils).to receive(:rm_rf).with(shared.archive_path)
      end

      it 'notifies the user' do
        expect_next_instance_of(NotificationService) do |instance|
          expect(instance).to receive(:project_not_exported)
        end
      end

      it 'notifies logger' do
        expect(service.instance_variable_get(:@logger)).to receive(:error)
      end

      it 'does not call the export strategy' do
        expect(service).not_to receive(:execute_after_export_action)
      end
    end

    context 'when one of the savers fail unexpectedly' do
      let(:archive_path) { shared.archive_path }

      before do
        allow(service).to receive_message_chain(:uploads_saver, :save).and_return(false)
      end

      it 'removes the remaining exported data' do
        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)

        expect(project.import_export_upload).to be_nil
        expect(File.exist?(shared.archive_path)).to eq(false)
      end
    end

    context 'when user does not have admin_project permission' do
      let!(:another_user) { create(:user) }

      subject(:service) { described_class.new(project, another_user) }

      it 'fails' do
        expected_message =
          "User with ID: %s does not have required permissions for Project: %s with ID: %s" %
            [another_user.id, project.name, project.id]
        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error).with_message(expected_message)
      end
    end

    it_behaves_like 'measurable service' do
      let(:base_log_data) do
        {
          class: described_class.name,
          current_user: user.name,
          project_full_path: project.full_path,
          file_path: shared.export_path
        }
      end

      after do
        service.execute(after_export_strategy)
      end
    end
  end
end
