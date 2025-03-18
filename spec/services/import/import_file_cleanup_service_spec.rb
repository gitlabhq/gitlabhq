# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ImportFileCleanupService, feature_category: :importers do
  subject(:service) { described_class.new }

  describe '#execute' do
    it 'enqueues a removal job for old import_file' do
      upload = create(
        :import_export_upload,
        updated_at: (described_class::LAST_MODIFIED + 1.hour).ago,
        import_file: fixture_file_upload('spec/fixtures/project_export.tar.gz')
      )

      expect(::Gitlab::Import::RemoveImportFileWorker).to receive(:perform_async).with(upload.id)

      service.execute
    end

    context 'when import_file is new' do
      it 'does not enqueue removal job' do
        create(
          :import_export_upload,
          updated_at: (described_class::LAST_MODIFIED - 1.hour).ago,
          import_file: fixture_file_upload('spec/fixtures/project_export.tar.gz')
        )

        expect(::Gitlab::Import::RemoveImportFileWorker).not_to receive(:perform_async)

        service.execute
      end
    end
  end
end
