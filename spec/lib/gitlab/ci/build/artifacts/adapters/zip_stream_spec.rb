# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Artifacts::Adapters::ZipStream do
  let(:file_name) { 'single_file.zip' }
  let(:fixture_path) { "lib/gitlab/ci/build/artifacts/adapters/zip_stream/#{file_name}" }
  let(:stream) { File.open(expand_fixture_path(fixture_path), 'rb') }

  describe '#initialize' do
    it 'initializes when stream is passed' do
      expect { described_class.new(stream) }.not_to raise_error
    end

    context 'when stream is not passed' do
      let(:stream) { nil }

      it 'raises an error' do
        expect { described_class.new(stream) }.to raise_error(described_class::InvalidStreamError)
      end
    end
  end

  describe '#each_blob' do
    let(:adapter) { described_class.new(stream) }

    context 'when stream is a zip file' do
      it 'iterates file content when zip file contains one file' do
        expect { |b| adapter.each_blob(&b) }
          .to yield_with_args("file 1 content\n")
      end

      context 'when zip file contains multiple files' do
        let(:file_name) { 'multiple_files.zip' }

        it 'iterates content of all files' do
          expect { |b| adapter.each_blob(&b) }
            .to yield_successive_args("file 1 content\n", "file 2 content\n")
        end
      end

      context 'when zip file includes files in a directory' do
        let(:file_name) { 'with_directory.zip' }

        it 'iterates contents from files only' do
          expect { |b| adapter.each_blob(&b) }
            .to yield_successive_args("file 1 content\n", "file 2 content\n")
        end
      end

      context 'when zip contains a file which decompresses beyond the size limit' do
        let(:file_name) { '200_mb_decompressed.zip' }

        it 'does not read the file' do
          expect { |b| adapter.each_blob(&b) }.not_to yield_control
        end
      end

      context 'when the zip contains too many files' do
        let(:file_name) { '100_files.zip' }

        it 'stops processing when the limit is reached' do
          expect { |b| adapter.each_blob(&b) }
            .to yield_control.exactly(described_class::MAX_FILES_PROCESSED).times
        end
      end

      context 'when stream is a zipbomb' do
        let(:file_name) { 'zipbomb.zip' }

        it 'does not read the file' do
          expect { |b| adapter.each_blob(&b) }.not_to yield_control
        end
      end
    end

    context 'when stream is not a zip file' do
      let(:stream) { File.open(expand_fixture_path('junit/junit.xml.gz'), 'rb') }

      it 'does not yield any data' do
        expect { |b| adapter.each_blob(&b) }.not_to yield_control
        expect { adapter.each_blob { |b| b } }.not_to raise_error
      end
    end
  end
end
