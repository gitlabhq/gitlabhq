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
    end

    context 'when file exceeds allowed decompressed size' do
      it 'returns false' do
        expect(subject.valid?).to eq(false)
      end
    end

    context 'when something goes wrong during decompression' do
      before do
        allow(subject.archive_file).to receive(:eof?).and_raise(StandardError)
      end

      it 'logs and tracks raised exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(StandardError))
        expect(Gitlab::Import::Logger).to receive(:info).with(hash_including(message: 'Decompressed archive size validation failed.'))

        subject.valid?
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
