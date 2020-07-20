# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Gitlab::ImportExport::Saver do
  let!(:project) { create(:project, :public, name: 'project') }
  let(:base_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:export_path) { "#{base_path}/project_tree_saver_spec/export" }
  let(:shared) { project.import_export_shared }

  subject { described_class.new(exportable: project, shared: shared) }

  before do
    allow(shared).to receive(:base_path).and_return(base_path)
    allow_next_instance_of(Gitlab::ImportExport) do |instance|
      allow(instance).to receive(:storage_path).and_return(export_path)
    end

    FileUtils.mkdir_p(shared.export_path)
    FileUtils.touch("#{shared.export_path}/tmp.bundle")
    allow(FileUtils).to receive(:rm_rf).and_call_original
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

  it 'removes tmp files' do
    subject.save

    expect(FileUtils).to have_received(:rm_rf).with(base_path)
    expect(Dir.exist?(base_path)).to eq(false)
  end
end
