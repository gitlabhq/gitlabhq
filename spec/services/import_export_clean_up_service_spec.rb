# frozen_string_literal: true

require 'spec_helper'

describe ImportExportCleanUpService do
  describe '#execute' do
    let(:service) { described_class.new }

    let(:tmp_import_export_folder) { 'tmp/gitlab_exports' }

    context 'when the import/export directory does not exist' do
      it 'does not remove any archives' do
        path = '/invalid/path/'
        stub_repository_downloads_path(path)

        expect(service).not_to receive(:clean_up_export_files)

        service.execute
      end
    end

    context 'when the import/export directory exists' do
      it 'removes old files' do
        in_directory_with_files(mtime: 2.days.ago) do |dir, files|
          service.execute

          files.each { |file| expect(File.exist?(file)).to eq false }
          expect(File.directory?(dir)).to eq false
        end
      end

      it 'does not remove new files' do
        in_directory_with_files(mtime: 2.hours.ago) do |dir, files|
          service.execute

          files.each { |file| expect(File.exist?(file)).to eq true }
          expect(File.directory?(dir)).to eq true
        end
      end
    end

    context 'with uploader exports' do
      it 'removes old files' do
        upload = create(:import_export_upload,
                        updated_at: 2.days.ago,
                        export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz'))

        expect { service.execute }.to change { upload.reload.export_file.file.nil? }.to(true)
      end

      it 'does not remove new files' do
        upload = create(:import_export_upload,
                        updated_at: 1.hour.ago,
                        export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz'))

        expect { service.execute }.not_to change { upload.reload.export_file.file.nil? }
      end
    end

    def in_directory_with_files(mtime:)
      Dir.mktmpdir do |tmpdir|
        stub_repository_downloads_path(tmpdir)
        dir = File.join(tmpdir, tmp_import_export_folder, 'subfolder')
        FileUtils.mkdir_p(dir)

        files = FileUtils.touch(file_list(dir) + [dir], mtime: mtime.to_time)

        yield(dir, files)
      end
    end

    def stub_repository_downloads_path(path)
      new_shared_settings = Settings.shared.merge('path' => path)
      allow(Settings).to receive(:shared).and_return(new_shared_settings)
    end

    def file_list(dir)
      Array.new(5) do |num|
        File.join(dir, "random-#{num}.tar.gz")
      end
    end
  end
end
