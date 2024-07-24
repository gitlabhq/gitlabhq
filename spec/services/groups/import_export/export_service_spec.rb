# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ImportExport::ExportService, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:group) { create(:group) }

  let(:exported_by_admin) { false }

  describe '#async_execute' do
    context 'when the job can be successfully scheduled' do
      let(:export_service) { described_class.new(group: group, user: user, exported_by_admin: exported_by_admin) }

      it 'enqueues an export job' do
        expect(GroupExportWorker)
          .to receive(:perform_async)
          .with(user.id, group.id, { exported_by_admin: exported_by_admin })

        export_service.async_execute
      end

      it 'returns truthy' do
        expect(export_service.async_execute).to be_present
      end

      context 'when the user was an admin' do
        let(:exported_by_admin) { true }

        it 'passes `exported_by_admin` correctly in the `params` hash' do
          expect(GroupExportWorker).to receive(:perform_async).with(user.id, group.id, { exported_by_admin: true })

          export_service.async_execute
        end
      end
    end

    context 'when the job cannot be scheduled' do
      let(:export_service) { described_class.new(group: group, user: user, exported_by_admin: exported_by_admin) }

      before do
        allow(GroupExportWorker).to receive(:perform_async).and_return(nil)
      end

      it 'returns falsey' do
        expect(export_service.async_execute).to be_falsey
      end
    end
  end

  describe '#execute' do
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:archive_path) { shared.archive_path }
    let(:service) do
      described_class.new(
        group: group,
        user: user,
        exported_by_admin: exported_by_admin,
        params: { shared: shared }
      )
    end

    before_all do
      group.add_owner(user)
    end

    after do
      FileUtils.rm_rf(archive_path)
    end

    it 'saves the version' do
      expect(Gitlab::ImportExport::VersionSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'saves the models using ndjson tree saver' do
      expect(Gitlab::ImportExport::Group::TreeSaver).to receive(:new).and_call_original

      service.execute
    end

    it 'compresses and removes tmp files' do
      expect(group.import_export_uploads).to be_empty
      expect(Gitlab::ImportExport::Saver).to receive(:new).and_call_original

      service.execute

      expect(Dir.exist?(shared.archive_path)).to eq false
      expect(File.exist?(group.import_export_upload_by_user(user).export_file.path)).to eq true
    end

    it 'notifies the user' do
      expect_next_instance_of(NotificationService) do |instance|
        expect(instance).to receive(:group_was_exported)
      end

      service.execute
    end

    it 'creates an audit event' do
      expect(Gitlab::Audit::Auditor).to receive(:audit).with(
        {
          name: 'group_export_created',
          author: user,
          scope: group,
          target: group,
          message: 'Group file export was created'
        }
      )

      service.execute
    end

    context 'when the user was an admin' do
      let(:exported_by_admin) { true }

      it 'logs group exported audit event' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(name: 'group_export_created'))

        service.execute
      end

      context 'when silent exports are enabled' do
        before do
          stub_application_setting(silent_admin_exports_enabled: true)
        end

        it 'does not create an audit event' do
          expect(Gitlab::Audit::Auditor).not_to receive(:audit)

          expect { service.execute }.not_to change { AuditEvent.count }
        end

        it 'does not create any Todos' do
          expect { service.execute }.not_to change { Todo.count }
        end
      end
    end

    context 'when saver succeeds' do
      it 'saves the group in the file system' do
        service.execute

        expect(group.import_export_upload_by_user(user).export_file.file).not_to be_nil
        expect(File.directory?(archive_path)).to eq(false)
        expect(File.exist?(shared.archive_path)).to eq(false)
      end
    end

    context 'when user does not have admin_group permission' do
      let_it_be(:another_user) { create(:user) }

      let(:service) do
        described_class.new(
          group: group,
          user: another_user,
          exported_by_admin: exported_by_admin,
          params: { shared: shared }
        )
      end

      let(:expected_message) do
        "User with ID: %s does not have required permissions for Group: %s with ID: %s" %
          [another_user.id, group.name, group.id]
      end

      it 'fails' do
        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error).with_message(expected_message)
      end

      it 'logs the error' do
        expect_next_instance_of(Gitlab::Export::Logger) do |logger|
          expect(logger).to receive(:error).with(
            group_id: group.id,
            group_name: group.name,
            errors: expected_message,
            message: 'Group Export failed'
          )
        end

        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
      end

      it 'tracks the error' do
        expect(shared).to receive(:error) { |param| expect(param.message).to eq expected_message }

        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
      end
    end

    context 'when export fails' do
      context 'when file saver fails' do
        before do
          allow_next_instance_of(Gitlab::ImportExport::Saver) do |saver|
            allow(saver).to receive(:save).and_return(false)
          end
        end

        it 'removes the remaining exported data' do
          expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)

          expect(group.import_export_uploads).to be_empty
          expect(Dir.exist?(shared.archive_path)).to eq(false)
        end

        it 'notifies the user about failed group export' do
          expect_next_instance_of(NotificationService) do |instance|
            expect(instance).to receive(:group_was_not_exported)
          end

          expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
        end
      end

      context 'when file compression fails' do
        before do
          allow(service).to receive_message_chain(:tree_exporter, :save).and_return(false)
        end

        it 'removes the remaining exported data' do
          allow_next_instance_of(Gitlab::ImportExport::Saver) do |saver|
            allow(saver).to receive(:compress_and_save).and_return(false)
          end

          expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)

          expect(group.import_export_uploads).to be_empty
          expect(Dir.exist?(shared.archive_path)).to eq(false)
        end

        it 'notifies logger' do
          allow(service).to receive_message_chain(:tree_exporter, :save).and_return(false)

          expect(service.instance_variable_get(:@logger)).to receive(:error)

          expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
        end
      end
    end

    context 'when there is an existing export file' do
      subject(:export_service) { described_class.new(group: group, user: user, exported_by_admin: exported_by_admin) }

      let(:import_export_upload) do
        create(
          :import_export_upload,
          group: group,
          export_file: fixture_file_upload('spec/fixtures/group_export.tar.gz'),
          user: user
        )
      end

      it 'replaces it' do
        existing_file = import_export_upload.export_file

        export_service.execute
        expect(import_export_upload.reload.export_file.path).not_to eq existing_file.path
      end
    end
  end
end
