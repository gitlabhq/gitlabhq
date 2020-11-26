# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Artifacts::Metadata do
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

  context 'metadata file exists' do
    describe '#find_entries! empty string' do
      subject { metadata('').find_entries! }

      it 'matches correct paths' do
        expect(subject.keys).to contain_exactly 'ci_artifacts.txt',
                                                'other_artifacts_0.1.2/',
                                                'rails_sample.jpg',
                                                'tests_encoding/'
      end

      it 'matches metadata for every path' do
        expect(subject.keys.count).to eq 4
      end

      it 'return Hashes for each metadata' do
        expect(subject.values).to all(be_kind_of(Hash))
      end
    end

    describe '#find_entries! other_artifacts_0.1.2/' do
      subject { metadata('other_artifacts_0.1.2/').find_entries! }

      it 'matches correct paths' do
        expect(subject.keys)
          .to contain_exactly 'other_artifacts_0.1.2/',
                             'other_artifacts_0.1.2/doc_sample.txt',
                             'other_artifacts_0.1.2/another-subdirectory/'
      end
    end

    describe '#find_entries! other_artifacts_0.1.2/another-subdirectory/' do
      subject { metadata('other_artifacts_0.1.2/another-subdirectory/').find_entries! }

      it 'matches correct paths' do
        expect(subject.keys)
          .to contain_exactly 'other_artifacts_0.1.2/another-subdirectory/',
                             'other_artifacts_0.1.2/another-subdirectory/empty_directory/',
                             'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif'
      end
    end

    describe '#find_entries! recursively for other_artifacts_0.1.2/' do
      subject { metadata('other_artifacts_0.1.2/', recursive: true).find_entries! }

      it 'matches correct paths' do
        expect(subject.keys)
          .to contain_exactly 'other_artifacts_0.1.2/',
                             'other_artifacts_0.1.2/doc_sample.txt',
                             'other_artifacts_0.1.2/another-subdirectory/',
                             'other_artifacts_0.1.2/another-subdirectory/empty_directory/',
                             'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif'
      end
    end

    describe '#to_entry' do
      subject { metadata('').to_entry }

      it { is_expected.to be_an_instance_of(Gitlab::Ci::Build::Artifacts::Metadata::Entry) }
    end

    describe '#full_version' do
      subject { metadata('').full_version }

      it { is_expected.to eq 'GitLab Build Artifacts Metadata 0.0.1' }
    end

    describe '#version' do
      subject { metadata('').version }

      it { is_expected.to eq '0.0.1' }
    end

    describe '#errors' do
      subject { metadata('').errors }

      it { is_expected.to eq({}) }
    end
  end

  context 'metadata file does not exist' do
    let(:metadata_file_path) { nil }

    describe '#find_entries!' do
      it 'raises error' do
        expect { metadata.find_entries! }.to raise_error(described_class::InvalidStreamError, /Invalid stream/)
      end
    end
  end

  context 'metadata file is invalid' do
    let(:metadata_file_path) { Rails.root + 'spec/fixtures/ci_build_artifacts.zip' }

    describe '#find_entries!' do
      it 'raises error' do
        expect { metadata.find_entries! }.to raise_error(described_class::InvalidStreamError, /not in gzip format/)
      end
    end
  end

  context 'generated metadata' do
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
