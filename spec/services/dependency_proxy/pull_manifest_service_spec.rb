# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::PullManifestService do
  include DependencyProxyHelpers

  let(:image) { 'alpine' }
  let(:tag) { '3.9' }
  let(:token) { Digest::SHA256.hexdigest('123') }
  let(:manifest) { { foo: 'bar' }.to_json }
  let(:digest) { '12345' }
  let(:content_type) { 'foo' }
  let(:headers) do
    { 'docker-content-digest' => digest, 'content-type' => content_type }
  end

  subject { described_class.new(image, tag, token).execute_with_manifest(&method(:check_response)) }

  context 'remote request is successful' do
    before do
      stub_manifest_download(image, tag, headers: headers)
    end

    it 'successfully returns the manifest' do
      def check_response(response)
        response[:file].rewind

        expect(response[:status]).to eq(:success)
        expect(response[:file].read).to eq(manifest)
        expect(response[:digest]).to eq(digest)
        expect(response[:content_type]).to eq(content_type)
      end

      subject
    end
  end

  context 'remote request is not found' do
    before do
      stub_manifest_download(image, tag, status: 404, body: 'Not found')
    end

    it 'returns a 404 not found error' do
      def check_response(response)
        expect(response[:status]).to eq(:error)
        expect(response[:http_status]).to eq(404)
        expect(response[:message]).to eq('Not found')
      end

      subject
    end
  end

  context 'net timeout exception' do
    before do
      manifest_link = DependencyProxy::Registry.manifest_url(image, tag)

      stub_full_request(manifest_link).to_timeout
    end

    it 'returns a 599 error' do
      def check_response(response)
        expect(response[:status]).to eq(:error)
        expect(response[:http_status]).to eq(599)
        expect(response[:message]).to eq('execution expired')
      end

      subject
    end
  end

  context 'no block is given' do
    subject { described_class.new(image, tag, token).execute_with_manifest }

    it { expect { subject }.to raise_error(ArgumentError, 'Block must be provided') }
  end
end
