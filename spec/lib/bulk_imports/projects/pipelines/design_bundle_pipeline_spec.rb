# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::DesignBundlePipeline, feature_category: :importers do
  let_it_be(:design) { create(:design, :with_file) }

  let(:portable) { create(:project) }
  let(:tmpdir) { Dir.mktmpdir }
  let(:design_bundle_path) {  File.join(tmpdir, 'design.bundle') }
  let(:entity) do
    create(:bulk_import_entity, :project_entity, project: portable, source_xid: nil)
  end

  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:pipeline) { described_class.new(context) }

  before do
    design.repository.bundle_to_disk(design_bundle_path)

    allow(portable).to receive(:lfs_enabled?).and_return(true)
    allow(Dir).to receive(:mktmpdir).with('bulk_imports').and_return(tmpdir)
    allow(pipeline).to receive(:set_source_objects_counter)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '#run' do
    it 'imports design repository into destination project and removes tmpdir' do
      allow(pipeline)
        .to receive(:extract)
        .and_return(BulkImports::Pipeline::ExtractedData.new(data: [design_bundle_path]))

      expect(portable.design_repository).to receive(:create_from_bundle).with(design_bundle_path).and_call_original

      pipeline.run

      expect(portable.design_repository.exists?).to eq(true)
    end

    it 'skips import if already cached' do
      allow(pipeline)
        .to receive(:extract)
        .and_return(BulkImports::Pipeline::ExtractedData.new(data: [design_bundle_path]))

      expect(portable.design_repository).to receive(:create_from_bundle).with(design_bundle_path).and_call_original

      pipeline.run

      expect(pipeline).not_to receive(:load)

      pipeline.run
    end
  end

  describe '#extract' do
    it 'downloads & extracts design bundle filepath' do
      download_service = instance_double("BulkImports::FileDownloadService")
      decompression_service = instance_double("BulkImports::FileDecompressionService")
      extraction_service = instance_double("BulkImports::ArchiveExtractionService")

      expect(BulkImports::FileDownloadService)
        .to receive(:new)
        .with(
          configuration: context.configuration,
          relative_url: "/#{entity.pluralized_name}/#{CGI.escape(entity.source_full_path)}" \
                        '/export_relations/download?relation=design',
          tmpdir: tmpdir,
          filename: 'design.tar.gz')
        .and_return(download_service)
      expect(BulkImports::FileDecompressionService)
        .to receive(:new)
        .with(tmpdir: tmpdir, filename: 'design.tar.gz')
        .and_return(decompression_service)
      expect(BulkImports::ArchiveExtractionService)
        .to receive(:new)
        .with(tmpdir: tmpdir, filename: 'design.tar')
        .and_return(extraction_service)

      expect(download_service).to receive(:execute)
      expect(decompression_service).to receive(:execute)
      expect(extraction_service).to receive(:execute)

      extracted_data = pipeline.extract(context)

      expect(extracted_data.data).to contain_exactly(design_bundle_path)
    end
  end

  describe '#load' do
    before do
      allow(pipeline)
        .to receive(:extract)
        .and_return(BulkImports::Pipeline::ExtractedData.new(data: [design_bundle_path]))
    end

    it 'creates design repository from bundle' do
      expect(portable.design_repository).to receive(:create_from_bundle).with(design_bundle_path).and_call_original

      pipeline.load(context, design_bundle_path)

      expect(portable.design_repository.exists?).to eq(true)
    end

    context 'when lfs is disabled' do
      it 'returns' do
        allow(portable).to receive(:lfs_enabled?).and_return(false)

        expect(portable.design_repository).not_to receive(:create_from_bundle)

        pipeline.load(context, design_bundle_path)

        expect(portable.design_repository.exists?).to eq(false)
      end
    end

    context 'when file does not exist' do
      it 'returns' do
        expect(portable.design_repository).not_to receive(:create_from_bundle)

        pipeline.load(context, File.join(tmpdir, 'bogus'))

        expect(portable.design_repository.exists?).to eq(false)
      end
    end

    context 'when path is directory' do
      it 'returns' do
        expect(portable.design_repository).not_to receive(:create_from_bundle)

        pipeline.load(context, tmpdir)

        expect(portable.design_repository.exists?).to eq(false)
      end
    end

    context 'when path is symlink' do
      it 'returns' do
        symlink = File.join(tmpdir, 'symlink')
        FileUtils.ln_s(design_bundle_path, symlink)

        expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(symlink).and_call_original
        expect(portable.design_repository).not_to receive(:create_from_bundle)

        pipeline.load(context, symlink)

        expect(portable.design_repository.exists?).to eq(false)
      end
    end

    context 'when path has multiple hard links' do
      it 'returns' do
        FileUtils.link(design_bundle_path, File.join(tmpdir, 'hard_link'))

        expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(design_bundle_path).and_call_original
        expect(portable.design_repository).not_to receive(:create_from_bundle)

        pipeline.load(context, design_bundle_path)

        expect(portable.design_repository.exists?).to eq(false)
      end
    end

    context 'when path is not under tmpdir' do
      it 'returns' do
        expect { pipeline.load(context, '/home/test.txt') }
          .to raise_error(StandardError, 'path /home/test.txt is not allowed')
      end
    end

    context 'when path is being traversed' do
      it 'raises an error' do
        expect { pipeline.load(context, File.join(tmpdir, '..')) }
          .to raise_error(Gitlab::PathTraversal::PathTraversalAttackError, 'Invalid path')
      end
    end
  end

  describe '#after_run' do
    it 'removes tmpdir' do
      allow(FileUtils).to receive(:rm_rf).and_call_original
      expect(FileUtils).to receive(:rm_rf).with(tmpdir).and_call_original

      pipeline.after_run(nil)

      expect(Dir.exist?(tmpdir)).to eq(false)
    end
  end
end
