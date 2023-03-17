# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryArchiveCleanUpService, feature_category: :source_code_management do
  subject(:service) { described_class.new }

  describe '#execute (new archive locations)' do
    let(:sha) { "0" * 40 }

    it 'removes outdated archives and directories in a new-style path' do
      in_directory_with_files("project-#{non_existing_record_id}/#{sha}", %w[tar tar.bz2 tar.gz zip], 3.hours) do |dirname, files|
        service.execute

        files.each { |filename| expect(File.exist?(filename)).to be_falsy }
        expect(File.directory?(dirname)).to be_falsy
        expect(File.directory?(File.dirname(dirname))).to be_falsy
      end
    end

    it 'removes outdated archives and directories in a versioned path' do
      in_directory_with_files("project-#{non_existing_record_id}/#{sha}/@v2", %w[tar tar.bz2 tar.gz zip], 3.hours) do |dirname, files|
        service.execute

        files.each { |filename| expect(File.exist?(filename)).to be_falsy }
        expect(File.directory?(dirname)).to be_falsy
        expect(File.directory?(File.dirname(dirname))).to be_falsy
      end
    end

    it 'does not remove directories when they contain outdated non-archives' do
      in_directory_with_files("project-#{non_existing_record_id}/#{sha}", %w[tar conf rb], 2.hours) do |dirname, files|
        service.execute

        expect(File.directory?(dirname)).to be_truthy
      end
    end

    it 'does not remove in-date archives in a new-style path' do
      in_directory_with_files("project-#{non_existing_record_id}/#{sha}", %w[tar tar.bz2 tar.gz zip], 1.hour) do |dirname, files|
        service.execute

        files.each { |filename| expect(File.exist?(filename)).to be_truthy }
      end
    end
  end

  describe '#execute (legacy archive locations)' do
    context 'when the downloads directory does not exist' do
      it 'does not remove any archives' do
        path = '/invalid/path/'
        stub_repository_downloads_path(path)

        allow(File).to receive(:directory?).and_call_original
        expect(File).to receive(:directory?).with(path).and_return(false)

        expect(service).not_to receive(:clean_up_old_archives)
        expect(service).not_to receive(:clean_up_empty_directories)

        service.execute
      end
    end

    context 'when the downloads directory exists' do
      shared_examples 'invalid archive files' do |dirname, extensions, mtime|
        it 'does not remove files and directory' do
          in_directory_with_files(dirname, extensions, mtime) do |dir, files|
            service.execute

            files.each { |file| expect(File.exist?(file)).to eq true }
            expect(File.directory?(dir)).to eq true
          end
        end
      end

      it 'removes files older than 2 hours that matches valid archive extensions' do
        # In macOS, the the `mmin` parameter for `find` rounds up, so add a full
        # minute to ensure these files are deemed old.
        in_directory_with_files('sample.git', %w[tar tar.bz2 tar.gz zip], 121.minutes) do |dir, files|
          service.execute

          files.each { |file| expect(File.exist?(file)).to eq false }
          expect(File.directory?(dir)).to eq false
        end
      end

      context 'with files older than 2 hours that does not matches valid archive extensions' do
        it_behaves_like 'invalid archive files', 'sample.git', %w[conf rb], 121.minutes
      end

      context 'with files older than 2 hours inside invalid directories' do
        it_behaves_like 'invalid archive files', 'john/t/doe/sample.git', %w[conf rb tar tar.gz], 121.minutes
      end

      context 'with files newer than 2 hours that matches valid archive extensions' do
        it_behaves_like 'invalid archive files', 'sample.git', %w[tar tar.bz2 tar.gz zip], 1.hour
      end

      context 'with files newer than 2 hours that does not matches valid archive extensions' do
        it_behaves_like 'invalid archive files', 'sample.git', %w[conf rb], 1.hour
      end

      context 'with files newer than 2 hours inside invalid directories' do
        it_behaves_like 'invalid archive files', 'sample.git', %w[conf rb tar tar.gz], 1.hour
      end
    end
  end

  def in_directory_with_files(dirname, extensions, mtime)
    Dir.mktmpdir do |tmpdir|
      stub_repository_downloads_path(tmpdir)
      dir = File.join(tmpdir, dirname)
      files = create_temporary_files(dir, extensions, mtime)

      yield(dir, files)
    end
  end

  def stub_repository_downloads_path(path)
    allow(Gitlab.config.gitlab).to receive(:repository_downloads_path).and_return(path)
  end

  def create_temporary_files(dir, extensions, mtime)
    FileUtils.mkdir_p(dir)
    FileUtils.touch(extensions.map { |ext| File.join(dir, "sample.#{ext}") }, mtime: Time.now.utc - mtime)
  end
end
