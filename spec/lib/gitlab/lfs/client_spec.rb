# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Lfs::Client do
  let(:base_url) { "https://example.com" }
  let(:username) { 'user' }
  let(:password) { 'password' }
  let(:credentials) { { user: username, password: password, auth_method: 'password' } }

  let(:basic_auth_headers) do
    { 'Authorization' => "Basic #{Base64.strict_encode64("#{username}:#{password}")}" }
  end

  let(:upload_action) do
    {
      "href" => "#{base_url}/some/file",
      "header" => {
        "Key" => "value"
      }
    }
  end

  subject(:lfs_client) { described_class.new(base_url, credentials: credentials) }

  describe '#batch' do
    let_it_be(:objects) { create_list(:lfs_object, 3) }

    context 'server returns 200 OK' do
      it 'makes a successful batch request' do
        stub = stub_batch(
          objects: objects,
          headers: basic_auth_headers
        ).to_return(
          status: 200,
          body: { 'objects' => 'anything', 'transfer' => 'basic' }.to_json,
          headers: { 'Content-Type' => 'application/vnd.git-lfs+json' }
        )

        result = lfs_client.batch('upload', objects)

        expect(stub).to have_been_requested
        expect(result).to eq('objects' => 'anything', 'transfer' => 'basic')
      end
    end

    context 'server returns 400 error' do
      it 'raises an error' do
        stub_batch(objects: objects, headers: basic_auth_headers).to_return(status: 400)

        expect { lfs_client.batch('upload', objects) }.to raise_error(/Failed/)
      end
    end

    context 'server returns 500 error' do
      it 'raises an error' do
        stub_batch(objects: objects, headers: basic_auth_headers).to_return(status: 400)

        expect { lfs_client.batch('upload', objects) }.to raise_error(/Failed/)
      end
    end

    context 'server returns an exotic transfer method' do
      it 'raises an error' do
        stub_batch(
          objects: objects,
          headers: basic_auth_headers
        ).to_return(
          status: 200,
          body: { 'transfer' => 'carrier-pigeon' }.to_json,
          headers: { 'Content-Type' => 'application/vnd.git-lfs+json' }
        )

        expect { lfs_client.batch('upload', objects) }.to raise_error(/Unsupported transfer/)
      end
    end

    def stub_batch(objects:, headers:, operation: 'upload', transfer: 'basic')
      objects = objects.map { |o| { oid: o.oid, size: o.size } }
      body = { operation: operation, 'transfers': [transfer], objects: objects }.to_json

      stub_request(:post, base_url + '/info/lfs/objects/batch').with(body: body, headers: headers)
    end
  end

  describe "#upload" do
    let_it_be(:object) { create(:lfs_object) }

    context 'server returns 200 OK to an authenticated request' do
      it "makes an HTTP PUT with expected parameters" do
        stub_upload(object: object, headers: upload_action['header']).to_return(status: 200)

        lfs_client.upload(object, upload_action, authenticated: true)
      end
    end

    context 'server returns 200 OK to an unauthenticated request' do
      it "makes an HTTP PUT with expected parameters" do
        stub = stub_upload(
          object: object,
          headers: basic_auth_headers.merge(upload_action['header'])
        ).to_return(status: 200)

        lfs_client.upload(object, upload_action, authenticated: false)

        expect(stub).to have_been_requested
      end
    end

    context 'LFS object has no file' do
      let(:object) { LfsObject.new }

      it 'makes an HJTT PUT with expected parameters' do
        stub = stub_upload(
          object: object,
          headers: upload_action['header']
        ).to_return(status: 200)

        lfs_client.upload(object, upload_action, authenticated: true)

        expect(stub).to have_been_requested
      end
    end

    context 'server returns 400 error' do
      it 'raises an error' do
        stub_upload(object: object, headers: upload_action['header']).to_return(status: 400)

        expect { lfs_client.upload(object, upload_action, authenticated: true) }.to raise_error(/Failed/)
      end
    end

    context 'server returns 500 error' do
      it 'raises an error' do
        stub_upload(object: object, headers: upload_action['header']).to_return(status: 500)

        expect { lfs_client.upload(object, upload_action, authenticated: true) }.to raise_error(/Failed/)
      end
    end

    def stub_upload(object:, headers:)
      stub_request(:put, upload_action['href']).with(
        body: object.file.read,
        headers: headers.merge('Content-Length' => object.size.to_s)
      )
    end
  end
end
