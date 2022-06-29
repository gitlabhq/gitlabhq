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

        before do
          allow(Process).to receive(:getpgid).and_return(2)
          allow(Open3).to receive(:popen3).and_return([std, std, std, wait_thr])
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
          expect(Process).to receive(:kill).with(-1, 2)
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
  end

  def create_compressed_file
    Zlib::GzipWriter.open(filepath) do |gz|
      gz.write('Hello World!')
    end
  end
end
