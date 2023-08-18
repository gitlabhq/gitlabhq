# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::DecompressedGzipSizeValidator, feature_category: :importers do
  let_it_be(:filepath) { File.join(Dir.tmpdir, 'decompressed_gzip_size_validator_spec.gz') }

  before_all do
    create_compressed_file
  end

  after(:all) do
    FileUtils.rm(filepath)
  end

  subject { described_class.new(archive_path: filepath, max_bytes: max_bytes) }

  describe '#valid?' do
    let(:max_bytes) { 20 }

    context 'when file does not exceed allowed decompressed size' do
      it 'returns true' do
        expect(subject.valid?).to eq(true)
      end

      context 'when the waiter thread no longer exists due to being terminated or crashing' do
        it 'gracefully handles the absence of the waiter without raising exception' do
          allow(Process).to receive(:getpgid).and_raise(Errno::ESRCH)

          expect(subject.valid?).to eq(true)
        end
      end
    end

    context 'when file exceeds allowed decompressed size' do
      let(:max_bytes) { 1 }

      it 'returns false' do
        expect(subject.valid?).to eq(false)
      end
    end

    context 'when exception occurs during header readings' do
      shared_examples 'raises exception and terminates validator process group' do
        let(:std) { instance_double(IO, close: nil) }
        let(:wait_thr) { double }
        let(:wait_threads) { [wait_thr, wait_thr] }

        before do
          allow(Process).to receive(:getpgid).and_return(2)
          allow(Open3).to receive(:pipeline_r).and_return([std, wait_threads])
          allow(wait_thr).to receive(:[]).with(:pid).and_return(1)
          allow(wait_thr).to receive(:value).and_raise(exception)
        end

        it 'terminates validator process group' do
          expect(Process).to receive(:kill).with(-1, 2).twice
          expect(subject.valid?).to eq(false)
        end
      end

      context 'when timeout occurs' do
        let(:exception) { Timeout::Error }

        include_examples 'raises exception and terminates validator process group'
      end

      context 'when exception occurs' do
        let(:error_message) { 'Error!' }
        let(:exception) { StandardError.new(error_message) }

        include_examples 'raises exception and terminates validator process group'
      end
    end

    describe 'archive path validation' do
      let(:filesize) { nil }

      context 'when archive path is traversed' do
        let(:filepath) { '/foo/../bar' }

        it 'does not pass validation' do
          expect(subject.valid?).to eq(false)
        end
      end
    end

    context 'when archive path is not a string' do
      let(:filepath) { 123 }

      it 'returns false' do
        expect(subject.valid?).to eq(false)
      end
    end

    context 'when archive path is a symlink' do
      let(:filepath) { File.join(Dir.tmpdir, 'symlink') }

      before do
        FileUtils.ln_s(filepath, filepath, force: true)
      end

      it 'returns false' do
        expect(subject.valid?).to eq(false)
      end
    end

    context 'when archive path has multiple hard links' do
      before do
        FileUtils.link(filepath, File.join(Dir.mktmpdir, 'hard_link'))
      end

      it 'returns false' do
        expect(subject).not_to be_valid
      end
    end

    context 'when archive path is not a file' do
      let(:filepath) { Dir.mktmpdir }
      let(:filesize) { File.size(filepath) }

      after do
        FileUtils.rm_rf(filepath)
      end

      it 'returns false' do
        expect(subject.valid?).to eq(false)
      end
    end
  end

  def create_compressed_file
    Zlib::GzipWriter.open(filepath) do |gz|
      gz.write('Hello World!')
    end
  end
end
