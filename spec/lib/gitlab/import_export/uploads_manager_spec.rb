require 'spec_helper'

describe Gitlab::ImportExport::UploadsManager do
  let(:shared) { project.import_export_shared }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:project) { create(:project) }
  let(:exported_file_path) { "#{shared.export_path}/uploads/#{upload.secret}/#{File.basename(upload.path)}" }

  subject(:manager) { described_class.new(project: project, shared: shared) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    FileUtils.mkdir_p(shared.export_path)
  end

  after do
    FileUtils.rm_rf(shared.export_path)
  end

  describe '#save' do
    context 'when the project has uploads locally stored' do
      let(:upload) { create(:upload, :issuable_upload, :with_file, model: project) }

      before do
        project.uploads << upload
      end

      it 'does not cause errors' do
        manager.save

        expect(shared.errors).to be_empty
      end

      it 'copies the file in the correct location when there is an upload' do
        manager.save

        expect(File).to exist(exported_file_path)
      end
    end

    context 'using object storage' do
      let!(:upload) { create(:upload, :issuable_upload, :object_storage, model: project) }

      before do
        stub_feature_flags(import_export_object_storage: true)
        stub_uploads_object_storage(FileUploader)
      end

      it 'saves the file' do
        fake_uri = double

        expect(fake_uri).to receive(:open).and_return(StringIO.new('File content'))
        expect(URI).to receive(:parse).and_return(fake_uri)

        manager.save

        expect(File.read(exported_file_path)).to eq('File content')
      end
    end

    describe '#restore' do
      context 'using object storage' do
        before do
          stub_feature_flags(import_export_object_storage: true)
          stub_uploads_object_storage(FileUploader)

          FileUtils.mkdir_p(File.join(shared.export_path, 'uploads/72a497a02fe3ee09edae2ed06d390038'))
          FileUtils.touch(File.join(shared.export_path, 'uploads/72a497a02fe3ee09edae2ed06d390038', "dummy.txt"))
        end

        it 'restores the file' do
          manager.restore

          expect(project.uploads.size).to eq(1)
          expect(project.uploads.first.build_uploader.filename).to eq('dummy.txt')
        end
      end
    end
  end
end
