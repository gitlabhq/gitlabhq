# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator, feature_category: :job_artifacts do
  include WorkhorseHelpers

  let_it_be(:file_path) { File.join(Dir.tmpdir, 'decompressed_archive_size_validator_spec.gz') }
  let(:file) { File.open(file_path) }
  let(:file_format) { :gzip }
  let(:max_bytes) { 20 }
  let(:gzip_valid?) { true }
  let(:validator) { instance_double(::Gitlab::Ci::DecompressedGzipSizeValidator, valid?: gzip_valid?) }

  before_all do
    Zlib::GzipWriter.open(file_path) do |gz|
      gz.write('Hello World!')
    end
  end

  after(:all) do
    FileUtils.rm(file_path)
  end

  before do
    allow(::Gitlab::Ci::DecompressedGzipSizeValidator)
      .to receive(:new)
      .and_return(validator)
  end

  subject { described_class.new(file: file, file_format: file_format, max_bytes: max_bytes) }

  shared_examples 'when file does not exceed allowed compressed size' do
    let(:gzip_valid?) { true }

    it 'passes validation' do
      expect { subject.validate! }.not_to raise_error
    end
  end

  shared_examples 'when file exceeds allowed decompressed size' do
    let(:gzip_valid?) { false }

    it 'raises an exception' do
      expect { subject.validate! }
        .to raise_error(Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator::FileDecompressionError)
    end
  end

  describe '#validate!' do
    it_behaves_like 'when file does not exceed allowed compressed size'

    it_behaves_like 'when file exceeds allowed decompressed size'
  end

  context 'when file is not provided' do
    let(:file) { nil }

    it 'passes validation' do
      expect { subject.validate! }.not_to raise_error
    end
  end

  context 'when local_archive_path is provided' do
    let(:file) { instance_double(JobArtifactUploader, path: 'some/remote/path') }

    subject do
      described_class.new(
        file: file, file_format: file_format, max_bytes: max_bytes, local_archive_path: file_path
      )
    end

    it 'validates the local copy instead of the file path' do
      expect(::Gitlab::Ci::DecompressedGzipSizeValidator)
        .to receive(:new)
        .with(archive_path: file_path, max_bytes: max_bytes)
        .and_return(validator)

      subject.validate!
    end

    it_behaves_like 'when file does not exceed allowed compressed size'

    it_behaves_like 'when file exceeds allowed decompressed size'
  end

  context 'when file_format is not on the list' do
    let_it_be(:file_format) { 'rar' }

    it 'passes validation' do
      expect { subject.validate! }.not_to raise_error
    end
  end
end
