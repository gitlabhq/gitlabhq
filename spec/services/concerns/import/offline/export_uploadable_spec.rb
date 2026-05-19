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
  let_it_be(:offline_export) { create(:offline_export, :with_configuration, user: user) }
  let(:client) { instance_double(Import::Clients::ObjectStorage) }

  before do
    allow(instance).to receive(:offline_storage_client).with(offline_export.configuration).and_return(client)
    allow(client).to receive(:request_url)
      .and_return('https://s3.example.com/bucket/exports/project_1/self.json.gz')
  end

  describe '#upload_directly_to_object_storage' do
    let(:export_prefix) { offline_export.configuration.export_prefix }

    context 'when the relation is not batched' do
      let(:export) do
        build(:bulk_import_export,
          project: project,
          relation: 'self',
          offline_export: offline_export,
          user: user
        )
      end

      let(:exported_filename) { '/tmp/export/self.json' }
      let(:compressed_filename) { "#{exported_filename}.gz" }
      let(:instance) { dummy_class.new(export, exported_filename, compressed_filename, project, 'self') }

      it 'uploads file to object storage using file path' do
        expect(client).to receive(:store_file).with(
          "#{export_prefix}/project_#{project.id}/self.json.gz",
          compressed_filename
        )

        instance.upload_directly_to_object_storage
      end
    end

    context 'when the relation is batched' do
      let(:export) do
        build(:bulk_import_export,
          project: project,
          relation: 'issues',
          offline_export: offline_export,
          user: user,
          batched: true
        )
      end

      let(:export_batch) { build(:bulk_import_export_batch, export: export) }
      let(:exported_filename) { '/tmp/export/issues.ndjson' }
      let(:compressed_filename) { "#{exported_filename}.gz" }
      let(:instance) do
        dummy_class.new(
          export, exported_filename, compressed_filename, project, 'issues', export_batch
        )
      end

      it 'uploads file to object storage using file path' do
        expect(client).to receive(:store_file).with(
          "#{export_prefix}/project_#{project.id}/issues/batch_#{export_batch.batch_number}.ndjson.gz",
          compressed_filename
        )

        instance.upload_directly_to_object_storage
      end
    end

    context 'when the upload URL is blocked' do
      before do
        stub_application_setting(deny_all_requests_except_allowed?: true)
      end

      let(:export) do
        build(:bulk_import_export,
          project: project,
          relation: 'self',
          offline_export: offline_export,
          user: user
        )
      end

      let(:exported_filename) { '/tmp/export/self.json' }
      let(:compressed_filename) { "#{exported_filename}.gz" }
      let(:instance) { dummy_class.new(export, exported_filename, compressed_filename, project, 'self') }

      it 'raises before store_file is called' do
        expect(client).not_to receive(:store_file)

        expect { instance.upload_directly_to_object_storage }
          .to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
      end
    end

    context 'when upload fails' do
      let(:export) do
        build(:bulk_import_export,
          project: project,
          relation: 'self',
          offline_export: offline_export,
          user: user
        )
      end

      let(:exported_filename) { '/tmp/export/self.json' }
      let(:compressed_filename) { "#{exported_filename}.gz" }
      let(:instance) { dummy_class.new(export, exported_filename, compressed_filename, project, 'self') }
      let(:upload_error) { Import::Clients::ObjectStorage::UploadError.new('Upload failed') }

      it 'propagates exception for Sidekiq retry' do
        allow(client).to receive(:store_file).and_raise(upload_error)

        expect { instance.upload_directly_to_object_storage }
          .to raise_error(Import::Clients::ObjectStorage::UploadError, 'Upload failed')
      end
    end
  end
end
