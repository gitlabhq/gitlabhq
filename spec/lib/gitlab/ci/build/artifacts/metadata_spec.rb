require 'spec_helper'

describe Gitlab::Ci::Build::Artifacts::Metadata do
  def metadata(path = '')
    described_class.new(metadata_file_path, path)
  end

  let(:metadata_file_path) do
    Rails.root + 'spec/fixtures/ci_build_artifacts_metadata.gz'
  end

  context 'metadata file exists' do
    describe '#exists?' do
      subject { metadata.exists? }
      it { is_expected.to be true }
    end

    describe '#match! ./' do
      subject { metadata('./').match! }

      it 'matches correct paths' do
        expect(subject.first).to contain_exactly 'ci_artifacts.txt',
                                                 'other_artifacts_0.1.2/',
                                                 'rails_sample.jpg'
      end

      it 'matches metadata for every path' do
        expect(subject.last.count).to eq 3
      end

      it 'return Hashes for each metadata' do
        expect(subject.last).to all(be_kind_of(Hash))
      end
    end

    describe '#match! other_artifacts_0.1.2' do
      subject { metadata('other_artifacts_0.1.2').match! }

      it 'matches correct paths' do
        expect(subject.first).
          to contain_exactly 'other_artifacts_0.1.2/doc_sample.txt',
                             'other_artifacts_0.1.2/another-subdirectory/'
      end
    end

    describe '#match! other_artifacts_0.1.2/another-subdirectory' do
      subject { metadata('other_artifacts_0.1.2/another-subdirectory/').match! }

      it 'matches correct paths' do
        expect(subject.first).
          to contain_exactly 'other_artifacts_0.1.2/another-subdirectory/empty_directory/',
                             'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif'
      end
    end

    describe '#to_string_path' do
      subject { metadata('').to_string_path }
      it { is_expected.to be_an_instance_of(Gitlab::StringPath) }
    end
  end

  context 'metadata file does not exist' do
    let(:metadata_file_path) { '' }

    describe '#exists?' do
      subject { metadata.exists? }
      it { is_expected.to be false }
    end

    describe '#match!' do
      it 'raises error' do
        expect { metadata.match! }.to raise_error(StandardError, /Metadata file not found/)
      end
    end
  end
end
