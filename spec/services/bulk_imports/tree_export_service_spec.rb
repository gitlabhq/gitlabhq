# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::TreeExportService do
  let_it_be(:project) { create(:project) }
  let_it_be(:export_path) { Dir.mktmpdir }
  let_it_be(:relation) { 'issues' }

  subject(:service) { described_class.new(project, export_path, relation) }

  describe '#execute' do
    it 'executes export service and archives exported data' do
      expect_next_instance_of(Gitlab::ImportExport::Json::StreamingSerializer) do |serializer|
        expect(serializer).to receive(:serialize_relation)
      end

      subject.execute
    end

    context 'when unsupported relation is passed' do
      it 'raises an error' do
        service = described_class.new(project, export_path, 'unsupported')

        expect { service.execute }.to raise_error(BulkImports::Error, 'Unsupported relation export type')
      end
    end
  end

  describe '#exported_filename' do
    it 'returns filename of the exported file' do
      expect(subject.exported_filename).to eq('issues.ndjson')
    end
  end
end
