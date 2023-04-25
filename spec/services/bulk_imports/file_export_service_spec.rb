# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileExportService, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:relations) do
    {
      'uploads' => BulkImports::UploadsExportService,
      'lfs_objects' => BulkImports::LfsObjectsExportService,
      'repository' => BulkImports::RepositoryBundleExportService,
      'design' => BulkImports::RepositoryBundleExportService
    }
  end

  describe '#execute' do
    it 'executes export service and archives exported data for each file relation' do
      relations.each do |relation, klass|
        Dir.mktmpdir do |export_path|
          service = described_class.new(project, export_path, relation, nil)

          expect_next_instance_of(klass) do |service|
            expect(service).to receive(:execute)
          end

          expect(service).to receive(:tar_cf).with(archive: File.join(export_path, "#{relation}.tar"), dir: export_path)

          service.execute
        end
      end
    end

    context 'when unsupported relation is passed' do
      it 'raises an error' do
        service = described_class.new(project, nil, 'unsupported', nil)

        expect { service.execute }.to raise_error(BulkImports::Error, 'Unsupported relation export type')
      end
    end
  end

  describe '#execute_batch' do
    it 'calls execute with provided array of record ids' do
      relations.each do |relation, klass|
        Dir.mktmpdir do |export_path|
          service = described_class.new(project, export_path, relation, nil)

          expect_next_instance_of(klass) do |service|
            expect(service).to receive(:execute).with({ batch_ids: [1, 2, 3] })
          end

          service.export_batch([1, 2, 3])
        end
      end
    end
  end

  describe '#exported_filename' do
    it 'returns filename of the exported file' do
      service = described_class.new(project, nil, 'uploads', nil)

      expect(service.exported_filename).to eq('uploads.tar')
    end
  end

  describe '#exported_objects_count' do
    context 'when relation is a collection' do
      it 'returns a number of exported relations' do
        %w[uploads lfs_objects].each do |relation|
          service = described_class.new(project, nil, relation, nil)

          allow(service).to receive_message_chain(:export_service, :exported_objects_count).and_return(10)

          expect(service.exported_objects_count).to eq(10)
        end
      end
    end

    context 'when relation is a repository' do
      it 'returns 1' do
        %w[repository design].each do |relation|
          service = described_class.new(project, nil, relation, nil)

          expect(service.exported_objects_count).to eq(1)
        end
      end
    end
  end
end
