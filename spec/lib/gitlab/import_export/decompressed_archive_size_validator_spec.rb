# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::DecompressedArchiveSizeValidator do
  let_it_be(:filepath) { File.join(Dir.tmpdir, 'decompressed_archive_size_validator_spec.gz') }

  before(:all) do
    create_compressed_file
  end

  after(:all) do
    FileUtils.rm(filepath)
  end

  subject { described_class.new(archive_path: filepath, max_bytes: max_bytes) }

  describe '#valid?' do
    let(:max_bytes) { 1 }

    context 'when file does not exceed allowed decompressed size' do
      let(:max_bytes) { 20 }

      it 'returns true' do
        expect(subject.valid?).to eq(true)
      end

      context 'when waiter thread no longer exists' do
        it 'does not raise exception' do
          allow(Process).to receive(:getpgid).and_raise(Errno::ESRCH)

          expect(subject.valid?).to eq(true)
        end
      end
    end

    context 'when file exceeds allowed decompressed size' do
      it 'logs error message returns false' do
        expect(Gitlab::Import::Logger)
          .to receive(:info)
          .with(
            import_upload_archive_path: filepath,
            import_upload_archive_size: File.size(filepath),
            message: 'Decompressed archive size limit reached'
          )
        expect(subject.valid?).to eq(false)
      end
    end

    context 'when exception occurs during decompression' do
      shared_examples 'logs raised exception and terminates validator process group' do
        let(:std) { double(:std, close: nil, value: nil) }
        let(:wait_thr) { double }
        let(:wait_threads) { [wait_thr, wait_thr] }

        before do
          allow(Process).to receive(:getpgid).and_return(2)
          allow(Open3).to receive(:pipeline_r).and_return([std, wait_threads])
          allow(wait_thr).to receive(:[]).with(:pid).and_return(1)
          allow(wait_thr).to receive(:value).and_raise(exception)
        end

        it 'logs raised exception and terminates validator process group' do
          expect(Gitlab::Import::Logger)
            .to receive(:info)
            .with(
              import_upload_archive_path: filepath,
              import_upload_archive_size: File.size(filepath),
              message: error_message
            )
          expect(Process).to receive(:kill).with(-1, 2).twice
          expect(subject.valid?).to eq(false)
        end
      end

      context 'when timeout occurs' do
        let(:error_message) { 'Timeout reached during archive decompression' }
        let(:exception) { Timeout::Error }

        include_examples 'logs raised exception and terminates validator process group'
      end

      context 'when exception occurs' do
        let(:error_message) { 'Error!' }
        let(:exception) { StandardError.new(error_message) }

        include_examples 'logs raised exception and terminates validator process group'
      end
    end

    context 'archive path validation' do
      let(:filesize) { nil }

      before do
        expect(Gitlab::Import::Logger)
          .to receive(:info)
          .with(
            import_upload_archive_path: filepath,
            import_upload_archive_size: filesize,
            message: error_message
          )
      end

      context 'when archive path is traversed' do
        let(:filepath) { '/foo/../bar' }
        let(:error_message) { 'Invalid path' }

        it 'returns false' do
          expect(subject.valid?).to eq(false)
        end
      end

      context 'when archive path is not a string' do
        let(:filepath) { 123 }
        let(:error_message) { 'Invalid path' }

        it 'returns false' do
          expect(subject.valid?).to eq(false)
        end
      end

      context 'which archive path is a symlink' do
        let(:filepath) { File.join(Dir.tmpdir, 'symlink') }
        let(:error_message) { 'Archive path is a symlink' }

        before do
          FileUtils.ln_s(filepath, filepath, force: true)
        end

        it 'returns false' do
          expect(subject.valid?).to eq(false)
        end
      end

      context 'when archive path is not a file' do
        let(:filepath) { Dir.mktmpdir }
        let(:filesize) { File.size(filepath) }
        let(:error_message) { 'Archive path is not a file' }

        after do
          FileUtils.rm_rf(filepath)
        end

        it 'returns false' do
          expect(subject.valid?).to eq(false)
        end
      end
    end
  end

  def create_compressed_file
    Zlib::GzipWriter.open(filepath) do |gz|
      gz.write('Hello World!')
    end
  end
end
