# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::CompressedJson do
  let_it_be(:decompressed_input) { '{"foo": "bar"}' }
  let_it_be(:input) { ActiveSupport::Gzip.compress(decompressed_input) }

  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:content_type) { 'application/json' }
  let(:env) do
    {
      'HTTP_CONTENT_ENCODING' => 'gzip',
      'REQUEST_METHOD' => 'POST',
      'CONTENT_TYPE' => content_type,
      'PATH_INFO' => path,
      'rack.input' => StringIO.new(input)
    }
  end

  shared_examples 'decompress middleware' do
    it 'replaces input with a decompressed content' do
      expect(app).to receive(:call)

      middleware.call(env)

      expect(env['rack.input'].read).to eq(decompressed_input)
      expect(env['CONTENT_LENGTH']).to eq(decompressed_input.length)
      expect(env['HTTP_CONTENT_ENCODING']).to be_nil
    end
  end

  describe '#call' do
    context 'with collector route' do
      let(:path) { '/api/v4/error_tracking/collector/1/store' }

      it_behaves_like 'decompress middleware'

      context 'with no Content-Type' do
        let(:content_type) { nil }

        it_behaves_like 'decompress middleware'
      end
    end

    context 'with collector route under relative url' do
      let(:path) { '/gitlab/api/v4/error_tracking/collector/1/store' }

      before do
        stub_config_setting(relative_url_root: '/gitlab')
      end

      it_behaves_like 'decompress middleware'
    end

    context 'with some other route' do
      let(:path) { '/api/projects/123' }

      it 'keeps the original input' do
        expect(app).to receive(:call)

        middleware.call(env)

        expect(env['rack.input'].read).to eq(input)
        expect(env['HTTP_CONTENT_ENCODING']).to eq('gzip')
      end
    end

    context 'payload is too large' do
      let(:body_limit) { Gitlab::Middleware::CompressedJson::MAXIMUM_BODY_SIZE }
      let(:decompressed_input) { 'a' * (body_limit + 100) }
      let(:input) { ActiveSupport::Gzip.compress(decompressed_input) }
      let(:path) { '/api/v4/error_tracking/collector/1/envelope' }

      it 'reads only limited size' do
        expect(middleware.call(env))
          .to eq([413, { 'Content-Type' => 'text/plain' }, ['Payload Too Large']])
      end
    end
  end
end
