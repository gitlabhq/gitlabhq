# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileDownloadService, feature_category: :importers do
  let_it_be(:bulk_import) { build_stubbed(:bulk_import, :with_configuration) }
  let_it_be(:entity, freeze: false) { build_stubbed(:bulk_import_entity, :with_portable, bulk_import: bulk_import) }
  let_it_be(:context, freeze: false) do
    BulkImports::Pipeline::Context.new(
      build_stubbed(:bulk_import_tracker, entity: entity),
      batch_number: 1
    )
  end

  let(:tmpdir) { Dir.mktmpdir }
  let(:relation) { 'labels' }
  let(:filename) { 'labels.ndjson.gz' }
  let(:filepath) { File.join(tmpdir, filename) }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '.for_context' do
    subject(:service_for_context) do
      described_class.for_context(
        context: context,
        relation: relation,
        tmpdir: tmpdir,
        filename: filename
      )
    end

    context 'when the import is online' do
      it 'initializes the service with an HttpFileDownloadStrategy' do
        strategy_double = instance_double(Import::BulkImports::HttpFileDownloadStrategy)

        allow(Import::BulkImports::HttpFileDownloadStrategy).to receive(:new).with(
          context: context,
          relative_url: context.entity.relation_download_url_path(relation, context.extra[:batch_number])
        ).and_return(strategy_double)

        expect(described_class).to receive(:new).with(
          tmpdir: tmpdir,
          filename: filename,
          file_download_strategy: strategy_double
        ).and_call_original

        expect(service_for_context).to be_a(described_class)
      end
    end

    context 'when the import is offline' do
      let_it_be(:offline_bulk_import, freeze: false) { create(:bulk_import) }
      let_it_be(:entity, freeze: false) { create(:bulk_import_entity, bulk_import: offline_bulk_import) }
      let_it_be(:entity_prefix) { 'group_123' }
      let_it_be(:offline_configuration) do
        create(
          :import_offline_configuration,
          bulk_import: offline_bulk_import,
          entity_prefix_mapping: { entity.source_full_path => entity_prefix }
        )
      end

      let_it_be(:context, freeze: false) do
        BulkImports::Pipeline::Context.new(
          create(:bulk_import_tracker, entity: entity),
          batch_number: 1
        )
      end

      it 'initializes the service with an ObjectStorageFileDownloadStrategy' do
        export_prefix = offline_configuration.export_prefix
        expected_object_key = "#{export_prefix}/#{entity_prefix}/labels/batch_1.ndjson.gz"
        strategy_double = instance_double(Import::Offline::Imports::ObjectStorageFileDownloadStrategy)

        allow(Import::Offline::Imports::ObjectStorageFileDownloadStrategy).to receive(:new).with(
          offline_configuration: context.offline_configuration,
          object_key: expected_object_key
        ).and_return(strategy_double)

        expect(described_class).to receive(:new).with(
          tmpdir: tmpdir,
          filename: filename,
          file_download_strategy: strategy_double
        ).and_call_original

        expect(service_for_context).to be_a(described_class)
      end
    end
  end

  describe '#execute' do
    let(:mock_strategy_class) do
      Class.new(Import::BulkImports::FileDownloadStrategy) do
        def initialize(options = {}); end

        def validate!; end

        def download_file(filepath); end
      end
    end

    let(:mock_strategy) { mock_strategy_class.new }

    subject(:service) do
      described_class.new(
        tmpdir: tmpdir,
        filename: filename,
        file_download_strategy: mock_strategy
      )
    end

    it 'validates the file download strategy' do
      expect(mock_strategy).to receive(:validate!)

      service.execute
    end

    it 'executes the file download strategy' do
      expect(mock_strategy).to receive(:download_file).with(filepath)

      service.execute
    end

    context 'when dir is not in tmpdir' do
      let(:tmpdir) { FileUtils.mkdir_p(Rails.root.join('tmp/import-test-dir')).first }

      it 'raises an error' do
        expect { service.execute }.to raise_error(
          StandardError,
          "path #{tmpdir} is not allowed"
        )
      end
    end
  end
end
