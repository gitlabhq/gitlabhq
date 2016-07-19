require 'spec_helper'

describe RepositoryArchiveCleanUpService, services: true do
  describe '#execute' do
    let(:path) { File.join(Rails.root, 'tmp/tests/shared/cache/archive') }

    subject(:service) { described_class.new }

    before do
      allow(Gitlab.config.gitlab).to receive(:repository_downloads_path).and_return(path)
    end

    context 'when the downloads directory does not exist' do
      it 'does not remove any archives' do
        expect(File).to receive(:directory?).with(path).and_return(false)
        expect(service).not_to receive(:clean_up_old_archives)
        expect(service).not_to receive(:clean_up_empty_directories)

        service.execute
      end
    end

    context 'when the downloads directory exists' do
      before do
        FileUtils.mkdir_p(path)
      end

      after do
        FileUtils.rm_rf(path)
      end

      context 'when archives older than 2 hours exists' do
        before do
          allow_any_instance_of(File).to receive(:mtime).and_return(2.hours.ago)
        end

        it 'removes old files that matches valid archive extensions' do
          dirname = File.join(path, 'sample.git')
          files = create_temporary_files(dirname, %w[tar tar.bz2 tar.gz zip])

          service.execute

          files.each { |file| expect(File.exist?(file)).to eq false }
          expect(File.directory?(dirname)).to eq false
        end

        it 'keeps old files that does not matches valid archive extensions' do
          dirname = File.join(path, 'sample.git')
          files = create_temporary_files(dirname, %w[conf rb])

          service.execute

          files.each { |file| expect(File.exist?(file)).to eq true }
          expect(File.directory?(dirname)).to eq true
        end

        it 'keeps old files inside invalid directories' do
          dirname = File.join(path, 'john_doe/sample.git')
          files = create_temporary_files(dirname, %w[conf rb tar tar.gz])

          service.execute

          files.each { |file| expect(File.exist?(file)).to eq true }
          expect(File.directory?(dirname)).to eq true
        end
      end

      context 'when archives older than 2 hours does not exist' do
        before do
          allow_any_instance_of(File).to receive(:mtime).and_return(1.hour.ago)
        end

        it 'keeps files that matches valid archive extensions' do
          dirname = File.join(path, 'sample.git')
          files = create_temporary_files(dirname, %w[tar tar.bz2 tar.gz zip])

          service.execute

          files.each { |file| expect(File.exist?(file)).to eq true }
          expect(File.directory?(dirname)).to eq true
        end

        it 'keeps files that does not matches valid archive extensions' do
          dirname = File.join(path, 'sample.git')
          files = create_temporary_files(dirname, %w[conf rb])

          service.execute

          files.each { |file| expect(File.exist?(file)).to eq true }
          expect(File.directory?(dirname)).to eq true
        end

        it 'keeps files inside invalid directories' do
          dirname = File.join(path, 'john_doe/sample.git')
          files = create_temporary_files(dirname, %w[conf rb tar tar.gz])

          service.execute

          files.each { |file| expect(File.exist?(file)).to eq true }
          expect(File.directory?(dirname)).to eq true
        end
      end

      def create_temporary_files(dirname, extensions)
        FileUtils.mkdir_p(dirname)

        extensions.flat_map do |extension|
          FileUtils.touch(File.join(dirname, "sample.#{extension}"))
        end
      end
    end
  end
end
