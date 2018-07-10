require 'spec_helper'

describe Gitlab::ImportExport::UploadsManager do
  let(:shared) { project.import_export_shared }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:project) { create(:project) }

  subject(:manager) { described_class.new(project: project, shared: shared) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    FileUtils.mkdir_p(shared.export_path)
  end

  after do
    FileUtils.rm_rf(shared.export_path)
  end

  describe '#copy' do
    context 'when the project has uploads locally stored' do
      let(:upload) { create(:upload) }

      before do
        project.uploads << upload
      end

      it 'does not cause errors' do
        manager.copy

        expect(shared.errors).to be_empty
      end

      it 'copies the file in the correct location when there is an upload' do
        manager.copy

        expect(File).to exist("#{shared.export_path}/uploads/#{File.basename(upload.path)}")
      end
    end
  end
end
