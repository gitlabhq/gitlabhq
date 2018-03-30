require 'spec_helper'

describe Gitlab::ImportExport::LfsSaver do
  let(:shared) { project.import_export_shared }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:project) { create(:project) }

  subject(:saver) { described_class.new(project: project, shared: shared) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    FileUtils.mkdir_p(shared.export_path)
  end

  after do
    FileUtils.rm_rf(shared.export_path)
  end

  describe '#save' do
    context 'when the project has LFS objects' do
      let(:lfs_object) { create(:lfs_object, :with_file) }

      before do
        project.lfs_objects << lfs_object
      end

      it 'does not cause errors' do
        saver.save

        expect(shared.errors).to be_empty
      end

      it 'copies the file in the correct location when there is an lfs object' do
        saver.save

        expect(File).to exist("#{shared.export_path}/lfs-objects/#{lfs_object.oid}")
      end
    end
  end
end
