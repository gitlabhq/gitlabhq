require 'spec_helper'

describe Ci::ArtifactBlob do
  let(:build) { create(:ci_build, :artifacts) }
  let(:entry) { build.artifacts_metadata_entry('other_artifacts_0.1.2/another-subdirectory/banana_sample.gif') }

  subject { described_class.new(entry) }

  describe '#id' do
    it 'returns a hash of the path' do
      expect(subject.id).to eq(Digest::SHA1.hexdigest(entry.path))
    end
  end

  describe '#name' do
    it 'returns the entry name' do
      expect(subject.name).to eq(entry.name)
    end
  end

  describe '#path' do
    it 'returns the entry path' do
      expect(subject.path).to eq(entry.path)
    end
  end

  describe '#size' do
    it 'returns the entry size' do
      expect(subject.size).to eq(entry.metadata[:size])
    end
  end

  describe '#mode' do
    it 'returns the entry mode' do
      expect(subject.mode).to eq(entry.metadata[:mode])
    end
  end

  describe '#external_storage' do
    it 'returns :build_artifact' do
      expect(subject.external_storage).to eq(:build_artifact)
    end
  end
end
