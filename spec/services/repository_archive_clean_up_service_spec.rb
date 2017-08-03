require 'spec_helper'

describe RepositoryArchiveCleanUpService do
  describe '#execute' do
    subject(:service) { described_class.new }

    context 'when the downloads directory does not exist' do
      it 'does not remove any archives' do
        path = '/invalid/path/'
        stub_repository_downloads_path(path)

        expect(File).to receive(:directory?).with(path).and_return(false)
        expect(service).not_to receive(:clean_up_old_archives)
        expect(service).not_to receive(:clean_up_empty_directories)

        service.execute
      end
    end

    context 'when the downloads directory exists' do
      shared_examples 'invalid archive files' do |dirname, extensions, mtime|
        it 'does not remove files and directoy' do
          in_directory_with_files(dirname, extensions, mtime) do |dir, files|
            service.execute

            files.each { |file| expect(File.exist?(file)).to eq true }
            expect(File.directory?(dir)).to eq true
          end
        end
      end

      it 'removes files older than 2 hours that matches valid archive extensions' do
        in_directory_with_files('sample.git', %w[tar tar.bz2 tar.gz zip], 2.hours) do |dir, files|
          service.execute

          files.each { |file| expect(File.exist?(file)).to eq false }
          expect(File.directory?(dir)).to eq false
        end
      end

      context 'with files older than 2 hours that does not matches valid archive extensions' do
        it_behaves_like 'invalid archive files', 'sample.git', %w[conf rb], 2.hours
      end

      context 'with files older than 2 hours inside invalid directories' do
        it_behaves_like 'invalid archive files', 'john_doe/sample.git', %w[conf rb tar tar.gz], 2.hours
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
      FileUtils.touch(extensions.map { |ext| File.join(dir, "sample.#{ext}") }, mtime: Time.now - mtime)
    end
  end
end
