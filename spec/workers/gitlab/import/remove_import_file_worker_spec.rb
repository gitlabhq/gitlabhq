# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::RemoveImportFileWorker, feature_category: :importers do
  let(:upload) do
    create(
      :import_export_upload,
      updated_at: 4.days.ago,
      import_file: fixture_file_upload('spec/fixtures/project_export.tar.gz')
    )
  end

  subject(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow_next_instance_of(::Import::Framework::Logger) do |logger|
        allow(logger).to receive(:info)
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [upload.id] }
    end

    it 'removes import_file of the upload and logs' do
      expect_next_instance_of(::Import::Framework::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            message: 'Removed ImportExportUpload import_file',
            project_id: upload.project_id,
            group_id: upload.group_id
          )
      end

      expect { worker.perform(upload.id) }.to change { upload.reload.import_file.file.nil? }.to(true)
    end

    context 'when upload cannot be found' do
      it 'returns' do
        expect(ImportExportUpload).to receive(:find_by_id).with(upload.id).and_return(nil)
        allow(upload).to receive(:remove_import_file!)

        worker.perform(upload.id)

        expect(upload).not_to have_received(:remove_import_file!)
      end
    end
  end
end
