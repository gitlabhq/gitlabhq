# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::ArchiveHeaderBuilder, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  let(:project) { instance_double(Project, path: 'my-project') }
  let(:repository) { instance_double(Repository, project: project) }
  let(:metadata) { { 'ArchivePrefix' => 'my-project-main-abc123' } }
  let(:ref) { 'main' }
  let(:format) { 'zip' }
  let(:append_sha) { true }
  let(:path) { nil }

  subject(:builder) do
    described_class.new(repository, ref: ref, format: format, append_sha: append_sha, path: path)
  end

  before do
    allow(repository).to receive(:archive_metadata).and_return(metadata)
  end

  describe '#metadata' do
    it 'calls repository.archive_metadata with correct arguments' do
      expect(repository).to receive(:archive_metadata).with(
        ref,
        '',
        format,
        append_sha: append_sha,
        path: path
      ).and_return(metadata)

      builder.metadata
    end

    it 'memoizes the result' do
      expect(repository).to receive(:archive_metadata).once.and_return(metadata)

      2.times { builder.metadata }
    end
  end

  describe '#filename' do
    it 'returns filename with archive prefix and format' do
      expect(builder.filename).to eq('my-project-main-abc123.zip')
    end

    context 'when format is tar.gz' do
      let(:format) { 'tar.gz' }
      let(:metadata) { { 'ArchivePrefix' => 'my-project-main-abc123' } }

      it 'returns filename with tar.gz extension' do
        expect(builder.filename).to eq('my-project-main-abc123.tar.gz')
      end
    end

    context 'when metadata is empty' do
      let(:metadata) { {} }

      it 'raises an exception' do
        expect { builder.filename }.to raise_error(RuntimeError, "Repository or ref not found")
      end
    end
  end

  describe '#content_type' do
    # Content types aligned with Workhorse behavior (workhorse/internal/git/archive.go):
    # - ZIP files get 'application/zip'
    # - All other formats get 'application/octet-stream'
    where(:format, :expected_content_type) do
      'zip'     | 'application/zip'
      'tar'     | 'application/octet-stream'
      'tar.gz'  | 'application/octet-stream'
      'tgz'     | 'application/octet-stream'
      'tar.bz2' | 'application/octet-stream'
      nil       | 'application/octet-stream'
    end

    with_them do
      it 'returns the correct content type' do
        builder = described_class.new(repository, ref: ref, format: format, append_sha: append_sha)
        expect(builder.content_type).to eq(expected_content_type)
      end
    end
  end

  describe '#content_disposition' do
    it 'returns attachment disposition with filename' do
      expected = ActionDispatch::Http::ContentDisposition.format(
        disposition: 'attachment',
        filename: 'my-project-main-abc123.zip'
      )

      expect(builder.content_disposition).to eq(expected)
    end

    context 'when metadata is empty' do
      let(:metadata) { {} }

      it 'raises an exception' do
        expect { builder.content_disposition }.to raise_error(RuntimeError, "Repository or ref not found")
      end
    end
  end

  describe 'format normalization' do
    it 'downcases the format' do
      builder = described_class.new(repository, ref: ref, format: 'ZIP', append_sha: append_sha)

      expect(builder.content_type).to eq('application/zip')
    end

    it 'defaults to tar.gz when format is nil' do
      builder = described_class.new(repository, ref: ref, format: nil, append_sha: append_sha)

      expect(builder.content_type).to eq('application/octet-stream')
    end
  end
end
