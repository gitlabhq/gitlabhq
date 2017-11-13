require 'spec_helper'

describe Ci::ArtifactBlob do
  set(:project) { create(:project, :public) }
  set(:build) { create(:ci_build, :artifacts, project: project) }
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

  describe '#external_url' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
    end

    context '.gif extension' do
      it 'returns nil' do
        expect(subject.external_url(build.project, build)).to be_nil
      end
    end

    context 'txt extensions' do
      let(:path) { 'other_artifacts_0.1.2/doc_sample.txt' }
      let(:entry) { build.artifacts_metadata_entry(path) }

      it 'returns a URL' do
        url = subject.external_url(build.project, build)

        expect(url).not_to be_nil
        expect(url).to eq("http://#{project.namespace.path}.#{Gitlab.config.pages.host}/-/#{project.path}/-/jobs/#{build.id}/artifacts/#{path}")
      end
    end
  end

  describe '#external_link?' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
    end

    context 'gif extensions' do
      it 'returns false' do
        expect(subject.external_link?(build)).to be false
      end
    end

    context 'txt extensions' do
      let(:entry) { build.artifacts_metadata_entry('other_artifacts_0.1.2/doc_sample.txt') }

      it 'returns true' do
        expect(subject.external_link?(build)).to be true
      end
    end
  end
end
