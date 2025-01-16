# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Artifacts::Metadata, feature_category: :job_artifacts do
  def metadata(path = '', **opts)
    described_class.new(metadata_file_stream, path, **opts)
  end

  let(:metadata_file_path) do
    Rails.root + 'spec/fixtures/ci_build_artifacts_metadata.gz'
  end

  let(:metadata_file_stream) do
    File.open(metadata_file_path) if metadata_file_path
  end

  after do
    metadata_file_stream&.close
  end

  describe '#to_entry' do
    subject(:entry) { metadata.to_entry }

    it { is_expected.to be_an_instance_of(Gitlab::Ci::Build::Artifacts::Metadata::Entry) }

    context 'when given path starts with a ./ prefix' do
      it 'instantiates the entry without the ./ prefix from the path' do
        meta = metadata("./some/path")
        expect(Gitlab::Ci::Build::Artifacts::Metadata::Entry).to receive(:new).with("some/path", {})
        meta.to_entry
      end
    end
  end

  describe '#full_version' do
    subject { metadata.full_version }

    it { is_expected.to eq 'GitLab Build Artifacts Metadata 0.0.2' }
  end

  describe '#version' do
    subject { metadata.version }

    it { is_expected.to eq '0.0.2' }
  end

  describe '#errors' do
    subject { metadata.errors }

    it { is_expected.to eq({}) }
  end

  describe '#find_entries!' do
    let(:recursive) { false }

    subject(:find_entries) { metadata(path, recursive: recursive).find_entries! }

    context 'when metadata file exists' do
      context 'and given path is an empty string' do
        let(:path) { '' }

        it 'returns paths to all files and directories at the root level' do
          expect(find_entries.keys).to contain_exactly(
            'ci_artifacts.txt',
            'other_artifacts_0.1.2/',
            'rails_sample.jpg',
            'tests_encoding/',
            'empty_image.png',
            'generated.yml'
          )
        end

        it 'return Hashes for each metadata' do
          expect(find_entries.values).to all(be_kind_of(Hash))
        end
      end

      shared_examples 'finding entries for a given path' do |options|
        let(:path) { "#{options[:path_prefix]}#{target_path}" }

        context 'when given path targets a directory at the root level' do
          let(:target_path) { 'other_artifacts_0.1.2/' }

          it 'returns paths to all files and directories at the first level of the directory' do
            expect(find_entries.keys).to contain_exactly(
              'other_artifacts_0.1.2/',
              'other_artifacts_0.1.2/.DS_Store',
              'other_artifacts_0.1.2/doc_sample.txt',
              'other_artifacts_0.1.2/another-subdirectory/'
            )
          end
        end

        context 'when given path targets a sub-directory' do
          let(:target_path) { 'other_artifacts_0.1.2/another-subdirectory/' }

          it 'returns paths to all files and directories at the first level of the sub-directory' do
            expect(find_entries.keys).to contain_exactly(
              'other_artifacts_0.1.2/another-subdirectory/',
              'other_artifacts_0.1.2/another-subdirectory/empty_directory/',
              'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif',
              'other_artifacts_0.1.2/another-subdirectory/.DS_Store'
            )
          end
        end

        context 'when given path targets a directory recursively' do
          let(:target_path) { 'other_artifacts_0.1.2/' }
          let(:recursive) { true }

          it 'returns all paths recursively within the target directory' do
            expect(subject.keys).to contain_exactly(
              'other_artifacts_0.1.2/',
              'other_artifacts_0.1.2/.DS_Store',
              'other_artifacts_0.1.2/doc_sample.txt',
              'other_artifacts_0.1.2/another-subdirectory/',
              'other_artifacts_0.1.2/another-subdirectory/empty_directory/',
              'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif',
              'other_artifacts_0.1.2/another-subdirectory/.DS_Store'
            )
          end
        end
      end

      context 'and given path does not start with a ./ prefix' do
        it_behaves_like 'finding entries for a given path', path_prefix: ''
      end

      context 'and given path starts with a ./ prefix' do
        it_behaves_like 'finding entries for a given path', path_prefix: './'
      end
    end

    context 'when metadata file stream is nil' do
      let(:path) { '' }
      let(:metadata_file_stream) { nil }

      it 'raises error' do
        expect { find_entries }.to raise_error(described_class::InvalidStreamError, /Invalid stream/)
      end
    end

    context 'when metadata file is invalid' do
      let(:path) { '' }
      let(:metadata_file_path) { Rails.root + 'spec/fixtures/ci_build_artifacts.zip' }

      it 'raises error' do
        expect { find_entries }.to raise_error(described_class::InvalidStreamError, /not in gzip format/)
      end

      context 'when metadata is an HttpIO stream' do
        let(:tmpfile) { Tempfile.new('test-metadata') }
        let(:url) { "file://#{tmpfile.path}" }
        let(:metadata_file_stream) { Gitlab::HttpIO.new(url, 0) }

        before do
          # Normally file:// URLs are not allowed, but bypass this for the sake of testing
          # so we don't have to run a Web server.
          allow(::Gitlab::UrlSanitizer).to receive(:valid?).with(url).and_return(true)
        end

        after do
          tmpfile.unlink
        end

        it 'raises error' do
          expect { find_entries }.to raise_error(described_class::InvalidStreamError, /not in gzip format/)
        end
      end
    end

    context 'with generated metadata' do
      let(:tmpfile) { Tempfile.new('test-metadata') }
      let(:generator) { CiArtifactMetadataGenerator.new(tmpfile) }
      let(:entry_count) { 5 }

      before do
        tmpfile.binmode

        (1..entry_count).each do |index|
          generator.add_entry("public/test-#{index}.txt")
        end

        generator.write
      end

      after do
        File.unlink(tmpfile.path)
      end

      describe '#find_entries!' do
        it 'reads expected number of entries' do
          stream = File.open(tmpfile.path)

          metadata = described_class.new(stream, 'public', recursive: true)

          expect(metadata.find_entries!.count).to eq entry_count
        end
      end
    end
  end
end
