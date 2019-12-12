# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe Gitlab::ImportExport::Saver do
  let!(:project) { create(:project, :public, name: 'project') }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:shared) { project.import_export_shared }

  subject { described_class.new(exportable: project, shared: shared) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

    FileUtils.mkdir_p(shared.export_path)
    FileUtils.touch("#{shared.export_path}/tmp.bundle")
  end

  after do
    FileUtils.rm_rf(export_path)
  end

  it 'saves the repo using object storage' do
    stub_uploads_object_storage(ImportExportUploader)

    subject.save

    expect(ImportExportUpload.find_by(project: project).export_file.url)
      .to match(%r[\/uploads\/-\/system\/import_export_upload\/export_file.*])
  end
end
