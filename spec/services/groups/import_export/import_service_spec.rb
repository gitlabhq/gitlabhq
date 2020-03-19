# frozen_string_literal: true

require 'spec_helper'

describe Groups::ImportExport::ImportService do
  describe '#execute' do
    let(:user) { create(:admin) }
    let(:group) { create(:group) }
    let(:service) { described_class.new(group: group, user: user) }
    let(:import_file) { fixture_file_upload('spec/fixtures/group_export.tar.gz') }

    let(:import_logger) { instance_double(Gitlab::Import::Logger) }

    subject { service.execute }

    before do
      ImportExportUpload.create(group: group, import_file: import_file)
    end

    context 'when user has correct permissions' do
      it 'imports group structure successfully' do
        expect(subject).to be_truthy
      end

      it 'removes import file' do
        subject

        expect(group.import_export_upload.import_file.file).to be_nil
      end

      it 'logs the import success' do
        allow(Gitlab::Import::Logger).to receive(:build).and_return(import_logger)

        expect(import_logger).to receive(:info).with(
          group_id:   group.id,
          group_name: group.name,
          message:    'Group Import/Export: Import succeeded'
        )

        subject
      end
    end

    context 'when user does not have correct permissions' do
      let(:user) { create(:user) }

      it 'logs the error and raises an exception' do
        allow(Gitlab::Import::Logger).to receive(:build).and_return(import_logger)

        expect(import_logger).to receive(:error).with(
          group_id:   group.id,
          group_name: group.name,
          message:    a_string_including('Errors occurred')
        )

        expect { subject }.to raise_error(Gitlab::ImportExport::Error)
      end

      it 'tracks the error' do
        shared = Gitlab::ImportExport::Shared.new(group)
        allow(Gitlab::ImportExport::Shared).to receive(:new).and_return(shared)

        expect(shared).to receive(:error) do |param|
          expect(param.message).to include 'does not have required permissions for'
        end

        expect { subject }.to raise_error(Gitlab::ImportExport::Error)
      end
    end

    context 'when there are errors with the import file' do
      let(:import_file) { fixture_file_upload('spec/fixtures/symlink_export.tar.gz') }

      before do
        allow(Gitlab::Import::Logger).to receive(:build).and_return(import_logger)
      end

      it 'logs the error and raises an exception' do
        expect(import_logger).to receive(:error).with(
          group_id:   group.id,
          group_name: group.name,
          message:    a_string_including('Errors occurred')
        )

        expect { subject }.to raise_error(Gitlab::ImportExport::Error)
      end
    end

    context 'when there are errors with the sub-relations' do
      let(:import_file) { fixture_file_upload('spec/fixtures/group_export_invalid_subrelations.tar.gz') }

      it 'successfully imports the group' do
        expect(subject).to be_truthy
      end

      it 'logs the import success' do
        allow(Gitlab::Import::Logger).to receive(:build).and_return(import_logger)

        expect(import_logger).to receive(:info).with(
          group_id:   group.id,
          group_name: group.name,
          message:    'Group Import/Export: Import succeeded'
        )

        subject
      end
    end
  end
end
