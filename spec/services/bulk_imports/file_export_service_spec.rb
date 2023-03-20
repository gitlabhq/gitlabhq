# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileExportService, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    it 'executes export service and archives exported data for each file relation' do
      relations = {
        'uploads' => BulkImports::UploadsExportService,
        'lfs_objects' => BulkImports::LfsObjectsExportService,
        'repository' => BulkImports::RepositoryBundleExportService,
        'design' => BulkImports::RepositoryBundleExportService
      }

      relations.each do |relation, klass|
        Dir.mktmpdir do |export_path|
          service = described_class.new(project, export_path, relation)

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
        service = described_class.new(project, nil, 'unsupported')

        expect { service.execute }.to raise_error(BulkImports::Error, 'Unsupported relation export type')
      end
    end
  end

  describe '#exported_filename' do
    it 'returns filename of the exported file' do
      service = described_class.new(project, nil, 'uploads')

      expect(service.exported_filename).to eq('uploads.tar')
    end
  end
end
