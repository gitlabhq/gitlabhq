# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::LfsObjectsPipeline, feature_category: :importers do
  let_it_be(:portable) { create(:project) }
  let_it_be(:oid) { 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' }

  let(:tmpdir) { Dir.mktmpdir }
  let(:entity) { create(:bulk_import_entity, :project_entity, project: portable, source_xid: nil) }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let(:lfs_dir_path) { tmpdir }
  let(:lfs_json_file_path) { File.join(lfs_dir_path, 'lfs_objects.json') }
  let(:lfs_file_path) { File.join(lfs_dir_path, oid) }

  subject(:pipeline) { described_class.new(context) }

  before do
    FileUtils.mkdir_p(lfs_dir_path)
    FileUtils.touch(lfs_json_file_path)
    FileUtils.touch(lfs_file_path)
    File.write(lfs_json_file_path, { oid => [0, 1, 2, nil] }.to_json)

    allow(Dir).to receive(:mktmpdir).with('bulk_imports').and_return(tmpdir)
    allow(pipeline).to receive(:set_source_objects_counter)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '#run' do
    it 'imports lfs objects into destination project and removes tmpdir' do
      allow(pipeline)
        .to receive(:extract)
        .and_return(BulkImports::Pipeline::ExtractedData.new(data: [lfs_json_file_path, lfs_file_path]))

      pipeline.run

      expect(portable.lfs_objects.count).to eq(1)
      expect(portable.lfs_objects_projects.count).to eq(4)
      expect(Dir.exist?(tmpdir)).to eq(false)
    end

    it 'does not call load on duplicates' do
      allow(pipeline)
        .to receive(:extract)
        .and_return(BulkImports::Pipeline::ExtractedData.new(data: [lfs_json_file_path, lfs_file_path]))

      pipeline.run

      expect(pipeline).not_to receive(:load)
      pipeline.run
    end
  end

  describe '#extract' do
    it 'downloads & extracts lfs objects filepaths' do
      download_service = instance_double("BulkImports::FileDownloadService")
      decompression_service = instance_double("BulkImports::FileDecompressionService")
      extraction_service = instance_double("BulkImports::ArchiveExtractionService")

      expect(BulkImports::FileDownloadService)
        .to receive(:new)
        .with(
          configuration: context.configuration,
          relative_url: "/#{entity.pluralized_name}/#{CGI.escape(entity.source_full_path)}/export_relations/download?relation=lfs_objects",
          tmpdir: tmpdir,
          filename: 'lfs_objects.tar.gz')
        .and_return(download_service)
      expect(BulkImports::FileDecompressionService).to receive(:new).with(tmpdir: tmpdir, filename: 'lfs_objects.tar.gz').and_return(decompression_service)
      expect(BulkImports::ArchiveExtractionService).to receive(:new).with(tmpdir: tmpdir, filename: 'lfs_objects.tar').and_return(extraction_service)

      expect(download_service).to receive(:execute)
      expect(decompression_service).to receive(:execute)
      expect(extraction_service).to receive(:execute)

      extracted_data = pipeline.extract(context)

      expect(extracted_data.data).to contain_exactly(lfs_json_file_path, lfs_file_path)
    end
  end

  describe '#load' do
    before do
      allow(pipeline)
        .to receive(:extract)
        .and_return(BulkImports::Pipeline::ExtractedData.new(data: [lfs_json_file_path, lfs_file_path]))
    end

    context 'when file path is lfs json' do
      it 'returns' do
        filepath = File.join(tmpdir, 'lfs_objects.json')

        allow(Gitlab::Json).to receive(:parse).with(filepath).and_return({})

        expect { pipeline.load(context, filepath) }.not_to change { portable.lfs_objects.count }
      end
    end

    context 'when file path is tar file' do
      it 'returns' do
        filepath = File.join(tmpdir, 'lfs_objects.tar')

        expect { pipeline.load(context, filepath) }.not_to change { portable.lfs_objects.count }
      end
    end

    context 'when lfs json read failed' do
      it 'raises an error' do
        File.write(lfs_json_file_path, 'invalid json')

        expect { pipeline.load(context, lfs_file_path) }.to raise_error(BulkImports::Error, 'LFS Objects JSON read failed')
      end
    end

    context 'when file path is being traversed' do
      it 'raises an error' do
        expect { pipeline.load(context, File.join(tmpdir, '..')) }.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError, 'Invalid path')
      end
    end

    context 'when file path is not under tmpdir' do
      it 'returns' do
        expect { pipeline.load(context, '/home/test.txt') }.to raise_error(StandardError, 'path /home/test.txt is not allowed')
      end
    end

    context 'when file path is symlink' do
      it 'returns' do
        symlink = File.join(tmpdir, 'symlink')
        FileUtils.ln_s(lfs_file_path, symlink)

        expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(symlink).and_call_original
        expect { pipeline.load(context, symlink) }.not_to change { portable.lfs_objects.count }
      end
    end

    context 'when file path shares multiple hard links' do
      it 'returns' do
        FileUtils.link(lfs_file_path, File.join(tmpdir, 'hard_link'))

        expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(lfs_file_path).and_call_original
        expect { pipeline.load(context, lfs_file_path) }.not_to change { portable.lfs_objects.count }
      end
    end

    context 'when path is a directory' do
      it 'returns' do
        expect { pipeline.load(context, Dir.tmpdir) }.not_to change { portable.lfs_objects.count }
      end
    end

    context 'lfs objects project' do
      context 'when lfs objects json is invalid' do
        context 'when oid value is not Array' do
          it 'does not create lfs objects project' do
            File.write(lfs_json_file_path, { oid => 'test' }.to_json)

            expect { pipeline.load(context, lfs_file_path) }.not_to change { portable.lfs_objects_projects.count }
          end
        end

        context 'when oid value is nil' do
          it 'does not create lfs objects project' do
            File.write(lfs_json_file_path, { oid => nil }.to_json)

            expect { pipeline.load(context, lfs_file_path) }.not_to change { portable.lfs_objects_projects.count }
          end
        end

        context 'when oid value is not allowed' do
          it 'does not create lfs objects project' do
            File.write(lfs_json_file_path, { oid => ['invalid'] }.to_json)

            expect { pipeline.load(context, lfs_file_path) }.not_to change { portable.lfs_objects_projects.count }
          end
        end

        context 'when repository type is duplicated' do
          it 'creates only one lfs objects project' do
            File.write(lfs_json_file_path, { oid => [0, 0, 1, 1, 2, 2] }.to_json)

            expect { pipeline.load(context, lfs_file_path) }.to change { portable.lfs_objects_projects.count }.by(3)
          end
        end
      end

      context 'when lfs objects project fails to be created' do
        it 'logs the failure' do
          allow_next_instance_of(LfsObjectsProject) do |object|
            allow(object).to receive(:persisted?).and_return(false)
          end

          expect_next_instance_of(BulkImports::Logger) do |logger|
            expect(logger).to receive(:warn).with(
              project_id: portable.id,
              message: 'Failed to save lfs objects project',
              errors: '',
              **Gitlab::ApplicationContext.current
            ).exactly(4).times
          end

          pipeline.load(context, lfs_file_path)
        end
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
