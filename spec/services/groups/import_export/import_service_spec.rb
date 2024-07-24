# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ImportExport::ImportService, feature_category: :importers do
  describe '#async_execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    before do
      allow(GroupImportWorker).to receive(:with_status).and_return(GroupImportWorker)
    end

    context 'when the job can be successfully scheduled' do
      subject(:import_service) { described_class.new(group: group, user: user) }

      it 'creates group import state' do
        import_service.async_execute

        import_state = group.import_state

        expect(import_state.user).to eq(user)
        expect(import_state.group).to eq(group)
      end

      it 'enqueues an import job' do
        allow(GroupImportWorker).to receive(:with_status).and_return(GroupImportWorker)

        expect(GroupImportWorker).to receive(:perform_async).with(user.id, group.id)

        import_service.async_execute
      end

      it 'marks the group import as in progress' do
        import_service.async_execute

        expect(group.import_state.in_progress?).to eq true
      end

      it 'returns truthy' do
        expect(import_service.async_execute).to be_truthy
      end
    end

    context 'when the job cannot be scheduled' do
      subject(:import_service) { described_class.new(group: group, user: user) }

      before do
        allow(GroupImportWorker).to receive(:perform_async).and_return(nil)
      end

      it 'returns falsey' do
        expect(import_service.async_execute).to be_falsey
      end

      it 'does not mark the group import as created' do
        expect { import_service.async_execute }.not_to change { group.import_state }
      end
    end
  end

  context 'when importing a ndjson export' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:import_file) { fixture_file_upload('spec/fixtures/group_export.tar.gz') }

    let(:import_logger) { instance_double(::Import::Framework::Logger) }

    subject(:service) { described_class.new(group: group, user: user) }

    before do
      ImportExportUpload.create!(group: group, import_file: import_file, user: user)

      allow(::Import::Framework::Logger).to receive(:build).and_return(import_logger)
      allow(import_logger).to receive(:error)
      allow(import_logger).to receive(:info)
      allow(import_logger).to receive(:warn)
      allow(FileUtils).to receive(:rm_rf).and_call_original
    end

    context 'when user has correct permissions' do
      before do
        group.add_owner(user)
      end

      it 'imports group structure successfully' do
        expect(service.execute).to be_truthy
      end

      it 'tracks the event' do
        service.execute

        expect_snowplow_event(
          category: 'Groups::ImportExport::ImportService',
          action: 'create',
          label: 'import_group_from_file'
        )

        expect_snowplow_event(
          category: 'Groups::ImportExport::ImportService',
          action: 'create',
          label: 'import_access_level',
          user: user,
          extra: { user_role: 'Owner', import_type: 'import_group_from_file' }
        )
      end

      it 'removes import file' do
        service.execute

        expect(group.import_export_upload_by_user(user).import_file.file).to be_nil
      end

      it 'removes tmp files' do
        shared = Gitlab::ImportExport::Shared.new(group)
        allow(Gitlab::ImportExport::Shared).to receive(:new).and_return(shared)

        service.execute

        expect(FileUtils).to have_received(:rm_rf).with(shared.base_path)
        expect(Dir.exist?(shared.base_path)).to eq(false)
      end

      it 'logs the import success' do
        expect(import_logger).to receive(:info).with(
          group_id: group.id,
          group_name: group.name,
          message: 'Group Import/Export: Import succeeded'
        ).once

        service.execute
      end
    end

    context 'when user does not have correct permissions' do
      it 'logs the error and raises an exception' do
        expect(import_logger).to receive(:error).with(
          group_id: group.id,
          group_name: group.name,
          message: a_string_including('Errors occurred')
        )

        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
      end

      it 'tracks the error' do
        shared = Gitlab::ImportExport::Shared.new(group)
        allow(Gitlab::ImportExport::Shared).to receive(:new).and_return(shared)

        expect(shared).to receive(:error) do |param|
          expect(param.message).to include 'does not have required permissions for'
        end

        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
      end
    end

    context 'when there are errors with the import file' do
      let(:import_file) { fixture_file_upload('spec/fixtures/symlink_export.tar.gz') }

      it 'logs the error and raises an exception' do
        expect(import_logger).to receive(:error).with(
          group_id: group.id,
          group_name: group.name,
          message: a_string_including('Errors occurred')
        ).once

        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
      end
    end

    context 'when there are errors with the sub-relations' do
      let(:import_file) { fixture_file_upload('spec/fixtures/group_export_invalid_subrelations.tar.gz') }

      before do
        group.add_owner(user)
      end

      it 'successfully imports the group' do
        expect(service.execute).to be_truthy
      end

      it 'logs the import success' do
        allow(::Import::Framework::Logger).to receive(:build).and_return(import_logger)

        expect(import_logger).to receive(:info).with(
          group_id: group.id,
          group_name: group.name,
          message: 'Group Import/Export: Import succeeded'
        )

        service.execute

        expect_snowplow_event(
          category: 'Groups::ImportExport::ImportService',
          action: 'create',
          label: 'import_access_level',
          user: user,
          extra: { user_role: 'Owner', import_type: 'import_group_from_file' }
        )
      end
    end
  end

  context 'when importing a json export' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:import_file) { fixture_file_upload('spec/fixtures/legacy_group_export.tar.gz') }

    let(:import_logger) { instance_double(::Import::Framework::Logger) }

    subject(:service) { described_class.new(group: group, user: user) }

    before do
      group.add_owner(user)
      ImportExportUpload.create!(group: group, import_file: import_file, user: user)

      allow(::Import::Framework::Logger).to receive(:build).and_return(import_logger)
      allow(import_logger).to receive(:error)
      allow(import_logger).to receive(:warn)
      allow(import_logger).to receive(:info)
    end

    it 'logs the error and raises an exception' do
      expect(import_logger).to receive(:error).with(
        group_id: group.id,
        group_name: group.name,
        message: a_string_including('Errors occurred')
      ).once

      expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
    end

    it 'tracks the error' do
      shared = Gitlab::ImportExport::Shared.new(group)
      allow(Gitlab::ImportExport::Shared).to receive(:new).and_return(shared)

      expect(shared).to receive(:error) do |param|
        expect(param.message).to include 'The import file is incompatible'
      end

      expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
    end
  end
end
