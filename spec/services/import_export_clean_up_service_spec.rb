# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportExportCleanUpService, feature_category: :importers do
  describe '#execute' do
    let(:service) { described_class.new }

    let(:tmp_import_export_folder) { 'tmp/gitlab_exports' }

    before do
      allow_next_instance_of(::Import::Framework::Logger) do |logger|
        allow(logger).to receive(:info)
      end
    end

    context 'when the import/export tmp storage directory does not exist' do
      it 'does not remove any archives' do
        path = '/invalid/path/'
        stub_repository_downloads_path(path)

        expect(service).not_to receive(:clean_up_export_files)

        service.execute
      end
    end

    context 'when the import/export tmp storage directory exists' do
      shared_examples 'removes old tmp files' do |subdir|
        it 'removes old files and logs' do
          expect_next_instance_of(::Import::Framework::Logger) do |logger|
            expect(logger)
              .to receive(:info)
              .with(
                message: 'Removed Import/Export tmp directory',
                dir_path: anything
              )
          end

          validate_cleanup(subdir: subdir, mtime: 2.days.ago, expected: false)
        end

        it 'does not remove new files or logs' do
          expect(::Import::Framework::Logger).not_to receive(:new)

          validate_cleanup(subdir: subdir, mtime: 2.hours.ago, expected: true)
        end
      end

      include_examples 'removes old tmp files', '@hashed'
      include_examples 'removes old tmp files', '@groups'
    end

    context 'with uploader exports' do
      it 'removes old files and logs' do
        upload = create(
          :import_export_upload,
          updated_at: 2.days.ago,
          export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz')
        )

        expect_next_instance_of(::Import::Framework::Logger) do |logger|
          expect(logger)
            .to receive(:info)
            .with(
              message: 'Removed Import/Export export_file',
              project_id: upload.project_id,
              group_id: upload.group_id
            )
        end

        expect { service.execute }.to change { upload.reload.export_file.file.nil? }.to(true)

        expect(ImportExportUpload.where(export_file: nil)).to include(upload)
      end

      it 'does not remove new files or logs' do
        upload = create(
          :import_export_upload,
          updated_at: 1.hour.ago,
          export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz')
        )

        expect(::Import::Framework::Logger).not_to receive(:new)

        expect { service.execute }.not_to change { upload.reload.export_file.file.nil? }

        expect(ImportExportUpload.where.not(export_file: nil)).to include(upload)
      end
    end

    def validate_cleanup(subdir:, mtime:, expected:)
      in_directory_with_files(mtime: mtime, subdir: subdir) do |dir, files|
        service.execute

        files.each { |file| expect(File.exist?(file)).to eq(expected) }
        expect(File.directory?(dir)).to eq(expected)
      end
    end

    def in_directory_with_files(mtime:, subdir:)
      Dir.mktmpdir do |tmpdir|
        stub_repository_downloads_path(tmpdir)
        hashed = Digest::SHA2.hexdigest(subdir)
        subdir_path = [subdir, hashed[0..1], hashed[2..3], hashed, hashed[4..10]]
        dir = File.join(tmpdir, tmp_import_export_folder, *[subdir_path])

        FileUtils.mkdir_p(dir)
        File.utime(mtime.to_i, mtime.to_i, dir)

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
