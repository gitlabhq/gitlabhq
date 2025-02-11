# frozen_string_literal: true

require 'spec_helper'
require 'zlib'

RSpec.describe BulkImports::Common::Extractors::NdjsonExtractor do
  let_it_be(:tmpdir) { Dir.mktmpdir }
  let_it_be(:import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject { described_class.new(relation: 'labels') }

  before do
    allow(FileUtils).to receive(:rm_rf).with(any_args).and_call_original

    subject.instance_variable_set(:@tmpdir, tmpdir)
  end

  after(:all) do
    FileUtils.rm_rf(tmpdir)
  end

  describe '#extract' do
    before do
      Zlib::GzipWriter.open(File.join(tmpdir, 'labels.ndjson.gz')) do |gz|
        gz.write [
          '{"title": "Title 1","description": "Description 1","type":"GroupLabel"}',
          '{"title": "Title 2","description": "Description 2","type":"GroupLabel"}'
        ].join("\n")
      end

      expect(BulkImports::FileDownloadService).to receive(:new)
        .with(
          configuration: context.configuration,
          relative_url: entity.relation_download_url_path('labels'),
          tmpdir: tmpdir,
          filename: 'labels.ndjson.gz')
        .and_return(instance_double(BulkImports::FileDownloadService, execute: nil))
    end

    it 'returns ExtractedData', :aggregate_failures do
      extracted_data = subject.extract(context)

      expect(extracted_data).to be_instance_of(BulkImports::Pipeline::ExtractedData)
      expect(extracted_data.data.to_a).to contain_exactly(
        [{ "title" => "Title 1", "description" => "Description 1", "type" => "GroupLabel" }, 0],
        [{ "title" => "Title 2", "description" => "Description 2", "type" => "GroupLabel" }, 1]
      )
    end
  end

  describe '#remove_tmpdir' do
    it 'removes tmp dir' do
      expect(FileUtils).to receive(:rm_rf).with(tmpdir).once

      subject.remove_tmpdir
    end
  end
end
