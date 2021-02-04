# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::HeadManifestService do
  include DependencyProxyHelpers

  let(:image) { 'alpine' }
  let(:tag) { 'latest' }
  let(:token) { Digest::SHA256.hexdigest('123') }
  let(:digest) { '12345' }
  let(:content_type) { 'foo' }
  let(:headers) do
    {
      'docker-content-digest' => digest,
      'content-type' => content_type
    }
  end

  subject { described_class.new(image, tag, token).execute }

  context 'remote request is successful' do
    before do
      stub_manifest_head(image, tag, headers: headers)
    end

    it { expect(subject[:status]).to eq(:success) }
    it { expect(subject[:digest]).to eq(digest) }
  end

  context 'remote request is not found' do
    before do
      stub_manifest_head(image, tag, status: 404, body: 'Not found')
    end

    it { expect(subject[:status]).to eq(:error) }
    it { expect(subject[:http_status]).to eq(404) }
    it { expect(subject[:message]).to eq('Not found') }
  end

  context 'net timeout exception' do
    before do
      manifest_link = DependencyProxy::Registry.manifest_url(image, tag)

      stub_full_request(manifest_link, method: :head).to_timeout
    end

    it { expect(subject[:status]).to eq(:error) }
    it { expect(subject[:http_status]).to eq(599) }
    it { expect(subject[:message]).to eq('execution expired') }
  end
end
