# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::ExportUploadable, feature_category: :importers do
  let(:dummy_class) do
    Class.new do
      include Import::Offline::ExportUploadable

      attr_reader :export, :exported_filename, :compressed_filename, :portable, :relation, :batch

      def initialize(export, exported_filename, compressed_filename, portable, relation, batch = nil)
        @export = export
        @exported_filename = exported_filename
        @compressed_filename = compressed_filename
        @portable = portable
        @relation = relation
        @batch = batch
      end
    end
  end

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:offline_export) { create(:offline_export, user: user) }

  let(:export) do
    create(:bulk_import_export,
      project: project,
      relation: 'issues',
      offline_export: offline_export,
      user: user
    )
  end

  let(:exported_filename) { '/tmp/export/issues.ndjson' }
  let(:compressed_filename) { "#{exported_filename}.gz" }
  let(:instance) { dummy_class.new(export, exported_filename, compressed_filename, project, 'issues') }

  describe '#upload_directly_to_object_storage' do
    let(:client) { instance_double(Import::Clients::ObjectStorage) }
    let(:configuration) { offline_export.configuration }

    before do
      allow(instance).to receive(:offline_storage_client).with(configuration).and_return(client)
      allow(instance).to receive(:offline_storage_filename)
                           .with(configuration).and_return('exports/project_1/issues.ndjson.gz')
    end

    it 'uploads file to object storage using file path' do
      expect(client).to receive(:store_file).with(
        'exports/project_1/issues.ndjson.gz',
        compressed_filename
      )

      instance.upload_directly_to_object_storage
    end

    context 'when upload fails' do
      let(:upload_error) { Import::Clients::ObjectStorage::UploadError.new('Upload failed') }

      it 'propagates exception for Sidekiq retry' do
        allow(client).to receive(:store_file).and_raise(upload_error)

        expect { instance.upload_directly_to_object_storage }
          .to raise_error(Import::Clients::ObjectStorage::UploadError, 'Upload failed')
      end
    end
  end

  describe '#offline_storage_client' do
    let(:configuration) { create(:offline_configuration, offline_export: offline_export) }

    it 'initializes ObjectStorage client with configuration' do
      expect(Import::Clients::ObjectStorage).to receive(:new).with(
        provider: configuration.provider,
        bucket: configuration.bucket,
        credentials: configuration.object_storage_credentials
      )

      instance.offline_storage_client(configuration)
    end
  end

  describe '#offline_storage_filename' do
    let(:configuration) { create(:offline_configuration, offline_export: offline_export, export_prefix: 'exports') }

    context 'with non-batched export' do
      it 'returns correct filename format' do
        allow(export).to receive(:batched?).and_return(false)

        filename = instance.offline_storage_filename(configuration)

        expect(filename).to eq("exports/project_#{project.id}/issues.ndjson.gz")
      end
    end

    context 'with batched export' do
      let(:batch) { create(:bulk_import_export_batch, export: export) }
      let(:instance) { dummy_class.new(export, exported_filename, compressed_filename, project, 'issues', batch) }

      it 'returns correct filename format with batch ID' do
        allow(export).to receive(:batched?).and_return(true)

        filename = instance.offline_storage_filename(configuration)

        expect(filename).to eq("exports/project_#{project.id}/issues/batch_#{batch.batch_number}.ndjson.gz")
      end
    end
  end

  describe '#extension' do
    it 'extracts the extension from the existing filename' do
      expect(instance.extension).to eq('.ndjson.gz')
    end

    context 'when existing filename has no extension' do
      let(:exported_filename) { '/path/to/somefile' }

      it 'returns the base compression extension' do
        expect(instance.extension).to eq('.gz')
      end
    end
  end
end
