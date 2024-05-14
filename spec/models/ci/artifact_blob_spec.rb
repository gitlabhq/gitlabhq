# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ArtifactBlob, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :public, path: 'project1') }
  let_it_be(:build) { create(:ci_build, :artifacts, project: project) }

  let(:pages_port) { nil }
  let(:entry) { build.artifacts_metadata_entry('other_artifacts_0.1.2/another-subdirectory/banana_sample.gif') }

  subject(:blob) { described_class.new(entry) }

  before do
    stub_pages_setting(
      enabled: true,
      artifacts_server: true,
      access_control: true,
      port: pages_port
    )
  end

  describe '#id' do
    it 'returns a hash of the path' do
      expect(blob.id).to eq(Digest::SHA1.hexdigest(entry.path))
    end
  end

  describe '#name' do
    it 'returns the entry name' do
      expect(blob.name).to eq(entry.name)
    end
  end

  describe '#path' do
    it 'returns the entry path' do
      expect(blob.path).to eq(entry.path)
    end
  end

  describe '#size' do
    it 'returns the entry size' do
      expect(blob.size).to eq(entry.metadata[:size])
    end

    context 'with an empty file' do
      let(:entry) { build.artifacts_metadata_entry('empty_image.png') }

      it 'returns 0' do
        expect(blob.size).to eq(0)
      end
    end
  end

  describe '#mode' do
    it 'returns the entry mode' do
      expect(blob.mode).to eq(entry.metadata[:mode])
    end
  end

  describe '#external_storage' do
    it 'returns :build_artifact' do
      expect(blob.external_storage).to eq(:build_artifact)
    end
  end

  describe '#external_url' do
    subject(:url) { blob.external_url(build) }

    context 'with not allowed extension' do
      it { is_expected.to be_nil }
    end

    context 'with allowed extension' do
      let(:path) { 'other_artifacts_0.1.2/doc_sample.txt' }
      let(:entry) { build.artifacts_metadata_entry(path) }

      it { is_expected.to eq("http://#{project.namespace.path}.example.com/-/project1/-/jobs/#{build.id}/artifacts/other_artifacts_0.1.2/doc_sample.txt") }

      context 'when port is configured' do
        let(:pages_port) { 1234 }

        it { is_expected.to eq("http://#{project.namespace.path}.example.com:1234/-/project1/-/jobs/#{build.id}/artifacts/other_artifacts_0.1.2/doc_sample.txt") }
      end
    end
  end

  describe '#external_link?' do
    context 'with not allowed extensions' do
      it 'returns false' do
        expect(blob.external_link?(build)).to be false
      end
    end

    context 'with allowed extensions' do
      let(:entry) { build.artifacts_metadata_entry('other_artifacts_0.1.2/doc_sample.txt') }

      it 'returns true' do
        expect(blob.external_link?(build)).to be true
      end
    end
  end
end
