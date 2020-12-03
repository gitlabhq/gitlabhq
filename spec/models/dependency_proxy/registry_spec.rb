# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::Registry, type: :model do
  let(:tag)      { '2.3.5-alpine' }
  let(:blob_sha) { '40bd001563085fc35165329ea1ff5c5ecbdbbeef' }

  context 'image name without namespace' do
    let(:image) { 'ruby' }

    describe '#auth_url' do
      it 'returns a correct auth url' do
        expect(described_class.auth_url(image))
          .to eq('https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/ruby:pull')
      end
    end

    describe '#manifest_url' do
      it 'returns a correct manifest url' do
        expect(described_class.manifest_url(image, tag))
          .to eq('https://registry-1.docker.io/v2/library/ruby/manifests/2.3.5-alpine')
      end
    end

    describe '#blob_url' do
      it 'returns a correct blob url' do
        expect(described_class.blob_url(image, blob_sha))
          .to eq('https://registry-1.docker.io/v2/library/ruby/blobs/40bd001563085fc35165329ea1ff5c5ecbdbbeef')
      end
    end
  end

  context 'image name with namespace' do
    let(:image) { 'foo/ruby' }

    describe '#auth_url' do
      it 'returns a correct auth url' do
        expect(described_class.auth_url(image))
          .to eq('https://auth.docker.io/token?service=registry.docker.io&scope=repository:foo/ruby:pull')
      end
    end

    describe '#manifest_url' do
      it 'returns a correct manifest url' do
        expect(described_class.manifest_url(image, tag))
          .to eq('https://registry-1.docker.io/v2/foo/ruby/manifests/2.3.5-alpine')
      end
    end

    describe '#blob_url' do
      it 'returns a correct blob url' do
        expect(described_class.blob_url(image, blob_sha))
          .to eq('https://registry-1.docker.io/v2/foo/ruby/blobs/40bd001563085fc35165329ea1ff5c5ecbdbbeef')
      end
    end
  end

  describe '#authenticate_header' do
    it 'returns the OAuth realm and service header' do
      expect(described_class.authenticate_header)
        .to eq("Bearer realm=\"#{Gitlab.config.gitlab.url}/jwt/auth\",service=\"dependency_proxy\"")
    end
  end
end
