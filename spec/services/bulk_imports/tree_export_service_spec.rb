# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::TreeExportService, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:export_path) { Dir.mktmpdir }

  let(:relation) { 'issues' }

  subject(:service) { described_class.new(project, export_path, relation, project.owner) }

  describe '#execute' do
    it 'executes export service and archives exported data' do
      expect_next_instance_of(Gitlab::ImportExport::Json::StreamingSerializer) do |serializer|
        expect(serializer).to receive(:serialize_relation)
      end

      subject.execute
    end

    context 'when unsupported relation is passed' do
      it 'raises an error' do
        service = described_class.new(project, export_path, 'unsupported', project.owner)

        expect { service.execute }.to raise_error(BulkImports::Error, 'Unsupported relation export type')
      end
    end

    context 'when relation is self' do
      let(:relation) { 'self' }

      it 'executes export on portable itself' do
        expect_next_instance_of(Gitlab::ImportExport::Json::StreamingSerializer) do |serializer|
          expect(serializer).to receive(:serialize_root)
        end

        subject.execute
      end
    end
  end

  describe '#exported_filename' do
    it 'returns filename of the exported file' do
      expect(subject.exported_filename).to eq('issues.ndjson')
    end

    context 'when relation is self' do
      let(:relation) { 'self' }

      it 'returns filename of the exported file' do
        expect(subject.exported_filename).to eq('self.json')
      end
    end
  end

  describe '#export_batch' do
    it 'serializes relation with specified ids' do
      expect_next_instance_of(Gitlab::ImportExport::Json::StreamingSerializer) do |serializer|
        expect(serializer).to receive(:serialize_relation).with(anything, batch_ids: [1, 2, 3])
      end

      subject.export_batch([1, 2, 3])
    end
  end
end
