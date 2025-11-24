# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'

RSpec.describe Gitlab::Middleware::SidekiqWebStatic do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:env) { { 'PATH_INFO' => path } }
  let(:status) { 200 }
  let(:headers) { {} }
  let(:body) { StringIO.new }

  before do
    allow(app).to receive(:call).with(env).and_return([status, headers, body])
  end

  describe '#call' do
    context 'with an /admin/sidekiq route' do
      let(:path) { '/admin/sidekiq/javascripts/application.js' }

      context 'when X-Sendfile header is present' do
        let(:file_content) { 'console.log("test");' }
        let(:temp_file) { Tempfile.new('test.js') }

        before do
          temp_file.write(file_content)
          temp_file.rewind
          headers['X-Sendfile'] = temp_file.path
        end

        after do
          temp_file.close
          temp_file.unlink
        end

        it 'removes the X-Sendfile header and reads the file content' do
          result_status, result_headers, result_body = middleware.call(env)

          expect(result_status).to eq(200)
          expect(result_headers['X-Sendfile']).to be_nil
          expect(result_headers['Content-Length']).to eq(file_content.bytesize.to_s)
          expect(result_body).to eq([file_content])
          expect(body).to be_closed
        end
      end

      context 'when X-Sendfile header points to a non-existent file' do
        before do
          headers['X-Sendfile'] = '/path/to/non/existent/file.js'
        end

        it 'returns a 404 response' do
          result_status, result_headers, result_body = middleware.call(env)

          expect(result_status).to eq(404)
          expect(result_headers).to eq({})
          expect(result_body).to eq(['File not found'])
        end
      end

      context 'when X-Sendfile header is not present' do
        it 'does not modify the response' do
          result_status, result_headers, result_body = middleware.call(env)

          expect(result_status).to eq(200)
          expect(result_headers).to eq(headers)
          expect(result_body).to eq(body)
        end
      end
    end

    context 'with some static asset route' do
      let(:path) { '/assets/test.png' }

      context 'when X-Sendfile header is present' do
        before do
          headers['X-Sendfile'] = '/path/to/file.png'
        end

        it 'does not modify the response' do
          result_status, result_headers, result_body = middleware.call(env)

          expect(result_status).to eq(200)
          expect(result_headers['X-Sendfile']).to eq('/path/to/file.png')
          expect(result_body).to eq(body)
        end
      end
    end
  end
end
