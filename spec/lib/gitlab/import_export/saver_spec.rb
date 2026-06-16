# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Gitlab::ImportExport::Saver, feature_category: :importers do
  let!(:project) { create(:project, :public, name: 'project') }
  let(:base_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:archive_path) { "#{base_path}/archive" }
  let(:export_path) { "#{archive_path}/export" }
  let(:shared) { project.import_export_shared }

  subject { described_class.new(exportable: project, shared: shared, user: project.creator) }

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

    subject.save # rubocop:disable Rails/SaveBang

    expect(ImportExportUpload.find_by(project: project).export_file.url)
      .to match(%r{/uploads/-/system/import_export_upload/export_file.*})
  end

  it 'logs metrics after saving' do
    stub_uploads_object_storage(ImportExportUploader)
    expect(Gitlab::Export::Logger).to receive(:info).with(
      hash_including(
        message: 'Export archive saved',
        exportable_class: 'Project',
        'correlation_id' => anything,
        archive_file: anything,
        compress_duration_s: anything
      )).and_call_original

    expect(Gitlab::Export::Logger).to receive(:info).with(
      hash_including(
        message: 'Export archive uploaded',
        exportable_class: 'Project',
        'correlation_id' => anything,
        archive_file: anything,
        compress_duration_s: anything,
        assign_duration_s: anything,
        upload_duration_s: anything,
        upload_bytes: anything,
        upload_id: kind_of(Integer),
        export_file_saved: anything,
        export_file_exists: anything,
        export_archive_exists: anything
      )).and_call_original

    subject.save # rubocop:disable Rails/SaveBang
  end

  it 'removes archive path and keeps base path untouched' do
    allow(shared).to receive(:archive_path).and_return(archive_path)

    subject.save # rubocop:disable Rails/SaveBang

    expect(FileUtils).not_to have_received(:rm_rf).with(base_path)
    expect(FileUtils).to have_received(:rm_rf).with(archive_path)
    expect(Dir.exist?(archive_path)).to eq(false)
  end

  context 'when the export_file column saved but CarrierWave reports no file' do
    it 'logs a warning so the divergence is visible before the after-export strategy runs' do
      stub_uploads_object_storage(ImportExportUploader)
      allow_next_instance_of(ImportExportUpload) do |upload|
        allow(upload).to receive(:export_file_exists?).and_return(false)
      end

      allow(Gitlab::Export::Logger).to receive(:info).and_call_original

      expect(Gitlab::Export::Logger).to receive(:warn).with(
        hash_including(
          message: 'Export file column saved but CarrierWave reports no file',
          upload_id: kind_of(Integer)
        )
      )

      subject.save # rubocop:disable Rails/SaveBang -- not an ActiveRecord
    end
  end

  context 'when export_archive_exists? raises an error' do
    it 'logs a warning, records export_archive_exists as false, and does not propagate the error' do
      stub_uploads_object_storage(ImportExportUploader)
      allow_next_instance_of(ImportExportUpload) do |upload|
        allow(upload).to receive(:export_archive_exists?).and_raise(StandardError, 'network error')
      end

      allow(Gitlab::Export::Logger).to receive(:info).and_call_original

      expect(Gitlab::Export::Logger).to receive(:warn).with(
        hash_including(message: 'Export archive existence check failed')
      )
      expect(Gitlab::Export::Logger).to receive(:info)
        .with(hash_including(message: 'Export archive uploaded', export_archive_exists: false))
        .and_call_original

      subject.save # rubocop:disable Rails/SaveBang -- not an ActiveRecord
    end
  end

  context 'when save throws an exception' do
    before do
      expect(subject).to receive(:save_upload).and_raise(SocketError.new)
    end

    it 'logs a saver error' do
      allow(Gitlab::Export::Logger).to receive(:info).with(anything).and_call_original
      expect(Gitlab::Export::Logger).to receive(:info).with(
        hash_including(
          message: 'Export archive saver failed',
          exportable_class: 'Project',
          'correlation_id' => anything
        )).and_call_original

      subject.save # rubocop:disable Rails/SaveBang
    end
  end
end
