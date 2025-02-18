# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::RepositoryBundlePipeline, feature_category: :importers do
  let_it_be(:source) { create(:project, :repository) }

  let(:portable) { create(:project) }
  let(:tmpdir) { Dir.mktmpdir }
  let(:bundle_path) { File.join(tmpdir, 'repository.bundle') }
  let(:entity) do
    create(:bulk_import_entity, :project_entity, project: portable, source_xid: nil)
  end

  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:pipeline) { described_class.new(context) }

  before do
    source.repository.bundle_to_disk(bundle_path)

    allow(Dir).to receive(:mktmpdir).with('bulk_imports').and_return(tmpdir)
    allow(pipeline).to receive(:set_source_objects_counter)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '#run' do
    before do
      allow(pipeline).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [bundle_path]))
    end

    it 'imports repository into destination project and removes tmpdir' do
      expect(portable.repository).to receive(:create_from_bundle).with(bundle_path).and_call_original

      pipeline.run

      expect(portable.repository.exists?).to eq(true)
      expect(Dir.exist?(tmpdir)).to eq(false)
    end

    it 'skips import if already cached' do
      expect(portable.repository).to receive(:create_from_bundle).with(bundle_path).and_call_original

      pipeline.run

      expect(pipeline).not_to receive(:load)

      pipeline.run
    end

    context 'when something goes wrong during import' do
      it 'marks entity as failed' do
        allow(pipeline).to receive(:load).and_raise(StandardError)

        pipeline.run

        expect(entity.failed?).to eq(true)
      end
    end
  end

  describe '#extract' do
    it 'downloads & extracts repository bundle filepath' do
      download_service = instance_double("BulkImports::FileDownloadService")
      decompression_service = instance_double("BulkImports::FileDecompressionService")
      extraction_service = instance_double("BulkImports::ArchiveExtractionService")

      expect(BulkImports::FileDownloadService)
        .to receive(:new)
        .with(
          configuration: context.configuration,
          relative_url: "/#{entity.pluralized_name}/#{CGI.escape(entity.source_full_path)}" \
                        '/export_relations/download?relation=repository',
          tmpdir: tmpdir,
          filename: 'repository.tar.gz')
        .and_return(download_service)
      expect(BulkImports::FileDecompressionService)
        .to receive(:new)
        .with(tmpdir: tmpdir, filename: 'repository.tar.gz')
        .and_return(decompression_service)
      expect(BulkImports::ArchiveExtractionService)
        .to receive(:new)
        .with(tmpdir: tmpdir, filename: 'repository.tar')
        .and_return(extraction_service)

      expect(download_service).to receive(:execute)
      expect(decompression_service).to receive(:execute)
      expect(extraction_service).to receive(:execute)

      extracted_data = pipeline.extract(context)

      expect(extracted_data.data).to contain_exactly(bundle_path)
    end
  end

  describe '#load' do
    before do
      allow(pipeline)
        .to receive(:extract)
        .and_return(BulkImports::Pipeline::ExtractedData.new(data: [bundle_path]))
    end

    it 'creates repository from bundle' do
      expect(portable.repository).to receive(:create_from_bundle).with(bundle_path).and_call_original

      pipeline.load(context, bundle_path)

      expect(portable.repository.exists?).to eq(true)
    end

    context 'when file does not exist' do
      it 'returns' do
        expect(portable.repository).not_to receive(:create_from_bundle)

        pipeline.load(context, File.join(tmpdir, 'bogus'))

        expect(portable.repository.exists?).to eq(false)
      end
    end

    context 'when path is directory' do
      it 'returns' do
        expect(portable.repository).not_to receive(:create_from_bundle)

        pipeline.load(context, tmpdir)

        expect(portable.repository.exists?).to eq(false)
      end
    end

    context 'when path is symlink' do
      it 'returns' do
        symlink = File.join(tmpdir, 'symlink')
        FileUtils.ln_s(bundle_path, symlink)

        expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(symlink).and_call_original
        expect(portable.repository).not_to receive(:create_from_bundle)

        pipeline.load(context, symlink)

        expect(portable.repository.exists?).to eq(false)
      end
    end

    context 'when path has mutiple hard links' do
      it 'returns' do
        FileUtils.link(bundle_path, File.join(tmpdir, 'hard_link'))

        expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(bundle_path).and_call_original
        expect(portable.repository).not_to receive(:create_from_bundle)

        pipeline.load(context, bundle_path)

        expect(portable.repository.exists?).to eq(false)
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
