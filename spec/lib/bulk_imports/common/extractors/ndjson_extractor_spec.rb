# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Extractors::NdjsonExtractor do
  let_it_be(:tmpdir) { Dir.mktmpdir }
  let_it_be(:filepath) { 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz' }
  let_it_be(:import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject { described_class.new(relation: 'labels') }

  before do
    allow(FileUtils).to receive(:remove_entry).with(any_args).and_call_original

    subject.instance_variable_set(:@tmp_dir, tmpdir)
  end

  after(:all) do
    FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir)
  end

  describe '#extract' do
    before do
      FileUtils.copy_file(filepath, File.join(tmpdir, 'labels.ndjson.gz'))

      allow_next_instance_of(BulkImports::FileDownloadService) do |service|
        allow(service).to receive(:execute)
      end
    end

    it 'returns ExtractedData' do
      extracted_data = subject.extract(context)
      label = extracted_data.data.first.first

      expect(extracted_data).to be_instance_of(BulkImports::Pipeline::ExtractedData)
      expect(label['title']).to include('Label')
      expect(label['description']).to include('Label')
      expect(label['type']).to eq('GroupLabel')
    end
  end

  describe '#remove_tmp_dir' do
    it 'removes tmp dir' do
      expect(FileUtils).to receive(:remove_entry).with(tmpdir).once

      subject.remove_tmp_dir
    end
  end
end
