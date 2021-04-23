# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Lfs::Client do
  let(:base_url) { "https://example.com" }
  let(:username) { 'user' }
  let(:password) { 'password' }
  let(:credentials) { { user: username, password: password } }
  let(:git_lfs_content_type) { 'application/vnd.git-lfs+json' }
  let(:git_lfs_user_agent) { "GitLab #{Gitlab::VERSION} LFS client" }

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

  let(:verify_action) do
    {
      "href" => "#{base_url}/some/file/verify",
      "header" => {
        "Key" => "value"
      }
    }
  end

  let(:authorized_upload_action) { upload_action.tap { |action| action['header']['Authorization'] = 'foo' } }
  let(:authorized_verify_action) { verify_action.tap { |action| action['header']['Authorization'] = 'foo' } }

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
          headers: { 'Content-Type' => git_lfs_content_type }
        )

        result = lfs_client.batch!('upload', objects)

        expect(stub).to have_been_requested
        expect(result).to eq('objects' => 'anything', 'transfer' => 'basic')
      end
    end

    context 'server returns 400 error' do
      it 'raises an error' do
        stub_batch(objects: objects, headers: basic_auth_headers).to_return(status: 400)

        expect { lfs_client.batch!('upload', objects) }.to raise_error(/Failed/)
      end
    end

    context 'server returns 500 error' do
      it 'raises an error' do
        stub_batch(objects: objects, headers: basic_auth_headers).to_return(status: 400)

        expect { lfs_client.batch!('upload', objects) }.to raise_error(/Failed/)
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
          headers: { 'Content-Type' => git_lfs_content_type }
        )

        expect { lfs_client.batch!('upload', objects) }.to raise_error(/Unsupported transfer/)
      end
    end

    def stub_batch(objects:, headers:, operation: 'upload', transfer: 'basic')
      objects = objects.as_json(only: [:oid, :size])
      body = { operation: operation, 'transfers': [transfer], objects: objects }.to_json

      headers = {
        'Accept' => git_lfs_content_type,
        'Content-Type' => git_lfs_content_type,
        'User-Agent' => git_lfs_user_agent
      }.merge(headers)

      stub_request(:post, base_url + '/info/lfs/objects/batch').with(body: body, headers: headers)
    end
  end

  describe "#upload" do
    let_it_be(:object) { create(:lfs_object) }

    context 'server returns 200 OK to an authenticated request' do
      it "makes an HTTP PUT with expected parameters" do
        stub_upload(object: object, headers: upload_action['header']).to_return(status: 200)

        lfs_client.upload!(object, upload_action, authenticated: true)
      end
    end

    context 'server returns 200 OK to an unauthenticated request' do
      it "makes an HTTP PUT with expected parameters" do
        stub = stub_upload(
          object: object,
          headers: basic_auth_headers.merge(upload_action['header'])
        ).to_return(status: 200)

        lfs_client.upload!(object, upload_action, authenticated: false)

        expect(stub).to have_been_requested
      end
    end

    context 'request is not marked as authenticated but includes an authorization header' do
      it 'prefers the provided authorization header' do
        stub = stub_upload(
          object: object,
          headers: authorized_upload_action['header']
        ).to_return(status: 200)

        lfs_client.upload!(object, authorized_upload_action, authenticated: false)

        expect(stub).to have_been_requested
      end
    end

    context 'LFS object has no file' do
      let(:object) { LfsObject.new }

      it 'makes an HTTP PUT with expected parameters' do
        stub = stub_upload(
          object: object,
          headers: upload_action['header']
        ).to_return(status: 200)

        lfs_client.upload!(object, upload_action, authenticated: true)

        expect(stub).to have_been_requested
      end
    end

    context 'server returns 400 error' do
      it 'raises an error' do
        stub_upload(object: object, headers: upload_action['header']).to_return(status: 400)

        expect { lfs_client.upload!(object, upload_action, authenticated: true) }.to raise_error(/Failed/)
      end
    end

    context 'server returns 500 error' do
      it 'raises an error' do
        stub_upload(object: object, headers: upload_action['header']).to_return(status: 500)

        expect { lfs_client.upload!(object, upload_action, authenticated: true) }.to raise_error(/Failed/)
      end
    end

    def stub_upload(object:, headers:)
      headers = {
        'Content-Type' => 'application/octet-stream',
        'Content-Length' => object.size.to_s,
        'User-Agent' => git_lfs_user_agent
      }.merge(headers)

      stub_request(:put, upload_action['href']).with(
        body: object.file.read,
        headers: headers.merge('Content-Length' => object.size.to_s)
      )
    end
  end

  describe "#verify" do
    let_it_be(:object) { create(:lfs_object) }

    context 'server returns 200 OK to an authenticated request' do
      it "makes an HTTP POST with expected parameters" do
        stub_verify(object: object, headers: verify_action['header']).to_return(status: 200)

        lfs_client.verify!(object, verify_action, authenticated: true)
      end
    end

    context 'server returns 200 OK to an unauthenticated request' do
      it "makes an HTTP POST with expected parameters" do
        stub = stub_verify(
          object: object,
          headers: basic_auth_headers.merge(upload_action['header'])
        ).to_return(status: 200)

        lfs_client.verify!(object, verify_action, authenticated: false)

        expect(stub).to have_been_requested
      end
    end

    context 'request is not marked as authenticated but includes an authorization header' do
      it 'prefers the provided authorization header' do
        stub = stub_verify(
          object: object,
          headers: authorized_verify_action['header']
        ).to_return(status: 200)

        lfs_client.verify!(object, authorized_verify_action, authenticated: false)

        expect(stub).to have_been_requested
      end
    end

    context 'server returns 400 error' do
      it 'raises an error' do
        stub_verify(object: object, headers: verify_action['header']).to_return(status: 400)

        expect { lfs_client.verify!(object, verify_action, authenticated: true) }.to raise_error(/Failed/)
      end
    end

    context 'server returns 500 error' do
      it 'raises an error' do
        stub_verify(object: object, headers: verify_action['header']).to_return(status: 500)

        expect { lfs_client.verify!(object, verify_action, authenticated: true) }.to raise_error(/Failed/)
      end
    end

    def stub_verify(object:, headers:)
      headers = {
        'Accept' => git_lfs_content_type,
        'Content-Type' => git_lfs_content_type,
        'User-Agent' => git_lfs_user_agent
      }.merge(headers)

      stub_request(:post, verify_action['href']).with(
        body: object.to_json(only: [:oid, :size]),
        headers: headers
      )
    end
  end
end
