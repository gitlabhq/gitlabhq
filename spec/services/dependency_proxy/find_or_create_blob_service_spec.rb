# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::FindOrCreateBlobService do
  include DependencyProxyHelpers

  let(:blob)  { create(:dependency_proxy_blob) }
  let(:group) { blob.group }
  let(:image) { 'alpine' }
  let(:tag)   { '3.9' }
  let(:token) { Digest::SHA256.hexdigest('123') }
  let(:blob_sha) { '40bd001563085fc35165329ea1ff5c5ecbdbbeef' }

  subject { described_class.new(group, image, token, blob_sha).execute }

  before do
    stub_registry_auth(image, token)
  end

  context 'no cache' do
    before do
      stub_blob_download(image, blob_sha)
    end

    it 'downloads blob from remote registry if there is no cached one' do
      expect(subject[:status]).to eq(:success)
      expect(subject[:blob]).to be_a(DependencyProxy::Blob)
      expect(subject[:blob]).to be_persisted
      expect(subject[:from_cache]).to eq false
    end
  end

  context 'cached blob' do
    let(:blob_sha) { blob.file_name.sub('.gz', '') }

    it 'uses cached blob instead of downloading one' do
      expect(subject[:status]).to eq(:success)
      expect(subject[:blob]).to be_a(DependencyProxy::Blob)
      expect(subject[:blob]).to eq(blob)
      expect(subject[:from_cache]).to eq true
    end
  end

  context 'no such blob exists remotely' do
    before do
      stub_blob_download(image, blob_sha, 404)
    end

    it 'returns error message and http status' do
      expect(subject[:status]).to eq(:error)
      expect(subject[:message]).to eq('Failed to download the blob')
      expect(subject[:http_status]).to eq(404)
    end
  end
end
