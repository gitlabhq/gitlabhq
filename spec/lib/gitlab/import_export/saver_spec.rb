require 'spec_helper'
require 'fileutils'

describe Gitlab::ImportExport::Saver do
  let!(:project) { create(:project, :public, name: 'project') }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:shared) { project.import_export_shared }
  subject { described_class.new(project: project, shared: shared) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

    FileUtils.mkdir_p(shared.export_path)
    FileUtils.touch("#{shared.export_path}/tmp.bundle")
  end

  after do
    FileUtils.rm_rf(export_path)
  end

  context 'local archive' do
    it 'saves the repo to disk' do
      stub_feature_flags(import_export_object_storage: false)

      subject.save

      expect(shared.errors).to be_empty
      expect(Dir.empty?(shared.archive_path)).to be false
    end
  end

  context 'object storage' do
    it 'saves the repo using object storage' do
      stub_feature_flags(import_export_object_storage: true)
      stub_uploads_object_storage(ImportExportUploader)

      subject.save

      expect(ImportExportUpload.find_by(project: project).export_file.url)
        .to match(%r[\/uploads\/-\/system\/import_export_upload\/export_file.*])
    end
  end
end
