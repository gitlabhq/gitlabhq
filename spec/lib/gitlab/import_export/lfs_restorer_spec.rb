require 'spec_helper'

describe Gitlab::ImportExport::LfsRestorer do
  include UploadHelpers

  let(:export_path) { "#{Dir.tmpdir}/lfs_object_restorer_spec" }
  let(:project) { create(:project) }
  let(:shared) { project.import_export_shared }
  subject(:restorer) { described_class.new(project: project, shared: shared) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    FileUtils.mkdir_p(shared.export_path)
  end

  after do
    FileUtils.rm_rf(shared.export_path)
  end

  describe '#restore' do
    context 'when the archive contains lfs files' do
      let(:dummy_lfs_file_path) { File.join(shared.export_path, 'lfs-objects', 'dummy') }

      def create_lfs_object_with_content(content)
        dummy_lfs_file = Tempfile.new('existing')
        File.write(dummy_lfs_file.path, content)
        size = dummy_lfs_file.size
        oid = LfsObject.calculate_oid(dummy_lfs_file.path)
        LfsObject.create!(oid: oid, size: size, file: dummy_lfs_file)
      end

      before do
        FileUtils.mkdir_p(File.dirname(dummy_lfs_file_path))
        File.write(dummy_lfs_file_path, 'not very large')
        allow(restorer).to receive(:lfs_file_paths).and_return([dummy_lfs_file_path])
      end

      it 'creates an lfs object for the project' do
        expect { restorer.restore }.to change { project.reload.lfs_objects.size }.by(1)
      end

      it 'assigns the file correctly' do
        restorer.restore

        expect(project.lfs_objects.first.file.read).to eq('not very large')
      end

      it 'links an existing LFS object if it existed' do
        lfs_object = create_lfs_object_with_content('not very large')

        restorer.restore

        expect(project.lfs_objects).to include(lfs_object)
      end

      it 'succeeds' do
        expect(restorer.restore).to be_truthy
        expect(shared.errors).to be_empty
      end

      it 'stores the upload' do
        expect_any_instance_of(LfsObjectUploader).to receive(:store!)

        restorer.restore
      end
    end

    context 'without any LFS-objects' do
      it 'succeeds' do
        expect(restorer.restore).to be_truthy
        expect(shared.errors).to be_empty
      end
    end
  end
end
