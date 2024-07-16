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

  context 'when the file is located in the cloud' do
    let(:remote_path) { File.join(remote_store_path, remote_id) }

    let(:file_url) { "http://s3.amazonaws.com/#{remote_path}" }
    let(:file) do
      instance_double(JobArtifactUploader,
        path: file_path,
        url: file_url,
        object_store: ObjectStorage::Store::REMOTE)
    end

    let(:remote_id) { 'generated-remote-id-12345' }
    let(:remote_store_path) { ObjectStorage::TMP_UPLOAD_PATH }

    before do
      stub_request(:get, %r{s3.amazonaws.com/#{remote_path}})
        .to_return(status: 200, body: File.read('spec/fixtures/build.env.gz'))
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
