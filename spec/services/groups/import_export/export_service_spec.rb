# frozen_string_literal: true

require 'spec_helper'

describe Groups::ImportExport::ExportService do
  describe '#execute' do
    let!(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:export_path) { shared.export_path }
    let(:service) { described_class.new(group: group, user: user, params: { shared: shared }) }

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves the models' do
      expect(Gitlab::ImportExport::GroupTreeSaver).to receive(:new).and_call_original

      service.execute
    end

    context 'when saver succeeds' do
      it 'saves the group in the file system' do
        service.execute

        expect(group.import_export_upload.export_file.file).not_to be_nil
        expect(File.directory?(export_path)).to eq(false)
        expect(File.exist?(shared.archive_path)).to eq(false)
      end
    end

    context 'when saving services fail' do
      before do
        allow(service).to receive_message_chain(:tree_exporter, :save).and_return(false)
      end

      it 'removes the remaining exported data' do
        allow_any_instance_of(Gitlab::ImportExport::Saver).to receive(:compress_and_save).and_return(false)

        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)

        expect(group.import_export_upload).to be_nil
        expect(File.directory?(export_path)).to eq(false)
        expect(File.exist?(shared.archive_path)).to eq(false)
      end

      it 'notifies logger' do
        expect_any_instance_of(Gitlab::Import::Logger).to receive(:error)

        expect { service.execute }.to raise_error(Gitlab::ImportExport::Error)
      end
    end
  end
end
