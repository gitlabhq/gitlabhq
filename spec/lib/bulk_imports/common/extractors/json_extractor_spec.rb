# frozen_string_literal: true

require 'spec_helper'
require 'zlib'

RSpec.describe BulkImports::Common::Extractors::JsonExtractor do
  subject { described_class.new(relation: 'self') }

  let_it_be(:tmpdir) { Dir.mktmpdir }
  let_it_be(:import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  before do
    allow(FileUtils).to receive(:rm_rf).with(any_args).and_call_original

    subject.instance_variable_set(:@tmpdir, tmpdir)
  end

  after(:all) do
    FileUtils.rm_rf(tmpdir)
  end

  describe '#extract' do
    before do
      Zlib::GzipWriter.open(File.join(tmpdir, 'self.json.gz')) do |gz|
        gz.write '{"name": "Name","description": "Description","avatar":{"url":null}}'
      end

      expect(BulkImports::FileDownloadService).to receive(:new)
        .with(
          configuration: context.configuration,
          relative_url: entity.relation_download_url_path('self'),
          tmpdir: tmpdir,
          filename: 'self.json.gz')
        .and_return(instance_double(BulkImports::FileDownloadService, execute: nil))
    end

    it 'returns ExtractedData', :aggregate_failures do
      extracted_data = subject.extract(context)

      expect(extracted_data).to be_instance_of(BulkImports::Pipeline::ExtractedData)
      expect(extracted_data.data).to contain_exactly(
        { 'name' => 'Name', 'description' => 'Description', 'avatar' => { 'url' => nil } }
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
