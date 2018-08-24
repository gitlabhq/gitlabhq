require 'spec_helper'

describe Gitlab::ImportExport::UploadsSaver do
  describe 'bundle a project Git repo' do
    let(:export_path) { "#{Dir.tmpdir}/uploads_saver_spec" }
    let(:shared) { project.import_export_shared }
    let(:upload) { create(:upload, :issuable_upload, model: project) }
    subject(:saver) { described_class.new(shared: shared, project: project) }

    before do
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

      FileUtils.mkdir_p(File.dirname(upload.absolute_path))
      FileUtils.touch(upload.absolute_path)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    describe 'legacy storage' do
      let(:project) { create(:project, :legacy_storage) }

      it 'saves the uploads successfully' do
        expect(saver.save).to be true
      end

      it 'copies the uploads to the export path' do
        saver.save

        uploads = Dir.glob(File.join(saver.uploads_export_path, '**/*')).map { |file| File.basename(file) }

        expect(uploads).to include(File.basename(upload.path))
      end

      context 'with orphaned project upload files' do
        before do
          upload.delete
        end

        after do
          File.delete(upload.absolute_path) if File.exist?(upload.absolute_path)
        end

        it 'excludes orphaned upload files' do
          saver.save

          uploads = Dir.glob(File.join(saver.uploads_export_path, '**/*')).map { |file| File.basename(file) }

          expect(uploads).not_to include(File.basename(upload.path))
        end
      end

      context 'with an upload missing its file' do
        before do
          File.delete(upload.absolute_path) if File.exist?(upload.absolute_path)
        end

        it 'does not cause errors' do
          saver.save

          expect(shared.errors).to be_empty
        end
      end
    end

    describe 'hashed storage' do
      let(:project) { create(:project) }

      it 'saves the uploads successfully' do
        expect(saver.save).to be true
      end

      it 'copies the uploads to the export path' do
        saver.save

        uploads = Dir.glob(File.join(saver.uploads_export_path, '**/*')).map { |file| File.basename(file) }

        expect(uploads).to include(File.basename(upload.path))
      end
    end
  end
end
