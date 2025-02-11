# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::UploadsPipeline, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  let(:tmpdir) { Dir.mktmpdir }
  let(:uploads_dir_path) { File.join(tmpdir, '72a497a02fe3ee09edae2ed06d390038') }
  let(:upload_file_path) { File.join(uploads_dir_path, 'upload.txt') }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:pipeline) { described_class.new(context) }

  before do
    stub_uploads_object_storage(FileUploader)

    FileUtils.mkdir_p(uploads_dir_path)
    FileUtils.touch(upload_file_path)

    allow(pipeline).to receive(:set_source_objects_counter)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  shared_examples 'uploads import' do
    describe '#run' do
      before do
        allow(Dir).to receive(:mktmpdir).with('bulk_imports').and_return(tmpdir)
        allow(pipeline).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [upload_file_path]))
      end

      it 'imports uploads into destination portable and removes tmpdir' do
        pipeline.run

        expect(portable.uploads.map { |u| u.retrieve_uploader.filename }).to include('upload.txt')

        expect(Dir.exist?(tmpdir)).to eq(false)
      end

      it 'skips loads on duplicates' do
        pipeline.run

        expect(pipeline).not_to receive(:load)

        pipeline.run
      end

      context 'when importing avatar' do
        let(:uploads_dir_path) { File.join(tmpdir, 'avatar') }

        it 'imports avatar' do
          FileUtils.touch(File.join(uploads_dir_path, 'avatar.png'))

          expect_next_instance_of(entity.update_service) do |service|
            expect(service).to receive(:execute)
          end

          pipeline.run
        end

        context 'when something goes wrong' do
          it 'raises exception' do
            allow_next_instance_of(entity.update_service) do |service|
              allow(service).to receive(:execute).and_return(nil)
            end

            pipeline.run

            expect(entity.failures.first.exception_class).to include('AvatarLoadingError')
          end
        end
      end
    end

    describe '#extract' do
      it 'downloads & extracts upload paths' do
        allow(Dir).to receive(:mktmpdir).and_return(tmpdir)

        download_service = instance_double("BulkImports::FileDownloadService")
        decompression_service = instance_double("BulkImports::FileDecompressionService")
        extraction_service = instance_double("BulkImports::ArchiveExtractionService")

        expect(BulkImports::FileDownloadService)
          .to receive(:new)
          .with(
            configuration: context.configuration,
            relative_url: "/#{entity.pluralized_name}/#{CGI.escape(entity.source_full_path)}/export_relations/download?relation=uploads",
            tmpdir: tmpdir,
            filename: 'uploads.tar.gz')
          .and_return(download_service)
        expect(BulkImports::FileDecompressionService).to receive(:new).with(tmpdir: tmpdir, filename: 'uploads.tar.gz').and_return(decompression_service)
        expect(BulkImports::ArchiveExtractionService).to receive(:new).with(tmpdir: tmpdir, filename: 'uploads.tar').and_return(extraction_service)

        expect(download_service).to receive(:execute)
        expect(decompression_service).to receive(:execute)
        expect(extraction_service).to receive(:execute)

        extracted_data = pipeline.extract(context)

        expect(extracted_data.data).to contain_exactly(uploads_dir_path, upload_file_path)
      end
    end

    describe '#load' do
      it 'creates a file upload' do
        expect { pipeline.load(context, upload_file_path) }.to change { portable.uploads.count }.by(1)
      end

      context 'when dynamic path is nil' do
        it 'returns' do
          path = File.join(tmpdir, 'test')
          FileUtils.touch(path)

          expect { pipeline.load(context, path) }.not_to change { portable.uploads.count }
        end
      end

      context 'when path is a directory' do
        it 'returns' do
          expect { pipeline.load(context, uploads_dir_path) }.not_to change { portable.uploads.count }
        end
      end

      context 'when path is a symlink' do
        it 'does not upload the file' do
          symlink = File.join(tmpdir, 'symlink')
          FileUtils.ln_s(upload_file_path, symlink)

          expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(symlink).and_call_original
          expect { pipeline.load(context, symlink) }.not_to change { portable.uploads.count }
        end
      end

      context 'when path has multiple hard links' do
        it 'does not upload the file' do
          FileUtils.link(upload_file_path, File.join(tmpdir, 'hard_link'))

          expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(upload_file_path).and_call_original
          expect { pipeline.load(context, upload_file_path) }.not_to change { portable.uploads.count }
        end
      end

      context 'when path traverses' do
        it 'does not upload the file' do
          path_traversal = "#{uploads_dir_path}/avatar/../../../../etc/passwd"
          expect { pipeline.load(context, path_traversal) }.to not_change { portable.uploads.count }.and raise_error(Gitlab::PathTraversal::PathTraversalAttackError)
        end
      end

      context 'when path is outside the tmpdir' do
        it 'does not upload the file' do
          path = "/etc/passwd"
          expect { pipeline.load(context, path) }.to not_change { portable.uploads.count }.and raise_error(StandardError, /not allowed/)
        end
      end
    end

    describe '#after_run' do
      before do
        allow(Dir).to receive(:mktmpdir).with('bulk_imports').and_return(tmpdir)
      end

      it 'removes tmp dir' do
        allow(FileUtils).to receive(:rm_rf).and_call_original
        expect(FileUtils).to receive(:rm_rf).with(tmpdir).and_call_original

        pipeline.after_run(nil)

        expect(Dir.exist?(tmpdir)).to eq(false)
      end
    end
  end

  context 'when importing to group' do
    let(:portable) { group }
    let(:entity) { create(:bulk_import_entity, :group_entity, group: group, source_xid: nil) }

    include_examples 'uploads import'
  end

  context 'when importing to project' do
    let(:portable) { project }
    let(:entity) { create(:bulk_import_entity, :project_entity, project: project, source_xid: nil) }

    include_examples 'uploads import'
  end
end
