# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::CorsStaticAssets, feature_category: :web_ide do
  let(:app) { double(:app) } # rubocop:disable RSpec/VerifiedDoubles -- stubbed app
  let(:middleware) { described_class.new(app) }

  let(:env) do
    {
      'REQUEST_METHOD' => request_method,
      'PATH_INFO' => path_info,
      'HTTP_ORIGIN' => origin_header
    }
  end

  let(:request_method) { 'GET' }
  let(:path_info) { '/assets/application.js' }
  let(:origin_header) { nil }
  let(:extension_host_domain) { 'cdn.web-ide.gitlab-static.net' }
  let(:fallback_response) { [200, { 'Content-Type' => 'application/javascript' }, ['OK']] }

  before do
    allow(app).to receive(:call).and_return(fallback_response)
    Gitlab::CurrentSettings.update!(
      vscode_extension_marketplace_extension_host_domain: extension_host_domain
    )
  end

  describe '#call' do
    context 'when request is for assets path' do
      let(:path_info) { '/assets/application.js' }

      shared_examples 'handles Origin header scenarios' do
        context 'when Origin header matches extension host domain' do
          it 'includes CORS headers' do
            status, headers, body = middleware.call(env)

            expect(status).to eq(expected_status)
            expect(headers['Access-Control-Allow-Origin']).to eq(origin_header)
            expect(headers['Access-Control-Allow-Methods']).to eq('GET, HEAD, OPTIONS')
            expect(headers['Vary']).to eq('Origin')
            expect(body).to eq(expected_body)
          end
        end
      end

      context 'with OPTIONS request' do
        let(:request_method) { 'OPTIONS' }
        let(:origin_header) { 'https://abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }
        let(:expected_status) { 204 }
        let(:expected_body) { [] }

        include_examples 'handles Origin header scenarios'

        it 'does not pass the request to other middlewares' do
          expect(app).not_to receive(:call)

          middleware.call(env)
        end
      end

      %w[GET HEAD].each do |method|
        context "with #{method} request" do
          let(:request_method) { method }
          let(:origin_header) { 'https://v--abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }
          let(:expected_status) { 200 }
          let(:expected_body) { ['OK'] }

          include_examples 'handles Origin header scenarios'

          it 'passes the request to other middlewares' do
            expect(app).to receive(:call).with(env)
              .and_return([200, { 'Content-Type' => 'application/javascript' }, ['OK']])

            middleware.call(env)
          end
        end
      end
    end

    context 'when Origin header does not match extension host domain' do
      let(:origin_header) { 'https://evil.com' }

      it 'does not handle the request' do
        expect(middleware.call(env)).to eq(fallback_response)
      end
    end

    context 'when Origin header is not present' do
      let(:origin_header) { nil }

      it 'does not handle the request' do
        expect(middleware.call(env)).to eq(fallback_response)
      end
    end

    context 'when request method is not GET, HEAD, or OPTIONS' do
      let(:path_info) { '/assets/application.js' }
      let(:request_method) { 'POST' }
      let(:origin_header) { 'https://abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }

      it 'passes through to the app without handling' do
        expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers['Access-Control-Allow-Origin']).to be_nil
        expect(body).to eq(['OK'])
      end
    end

    context 'when path does not start with /assets/' do
      let(:request_method) { 'GET' }

      [
        '/api/v4/projects',
        '/asset/file.js', # singular 'asset'
        '/public/assets/file.js', # nested assets
        '/'
      ].each do |non_asset_path|
        context "with path #{non_asset_path}" do
          let(:path_info) { non_asset_path }
          let(:origin_header) { 'https://abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }

          it 'passes through to the app without handling' do
            expect(app).to receive(:call).with(env)

            middleware.call(env)
          end
        end
      end
    end

    context 'when merging headers from app response' do
      let(:path_info) { '/assets/application.js' }
      let(:request_method) { 'GET' }
      let(:origin_header) { 'https://abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }

      it 'preserves headers from the app response' do
        app_headers = {
          'Content-Type' => 'application/javascript',
          'Cache-Control' => 'public, max-age=3600',
          'X-Custom-Header' => 'value'
        }
        allow(app).to receive(:call).with(env).and_return([200, app_headers, ['OK']])

        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers['Content-Type']).to eq('application/javascript')
        expect(headers['Cache-Control']).to eq('public, max-age=3600')
        expect(headers['X-Custom-Header']).to eq('value')
        expect(headers['Access-Control-Allow-Origin']).to eq(origin_header)
        expect(headers['Access-Control-Allow-Methods']).to eq('GET, HEAD, OPTIONS')
        expect(headers['Vary']).to eq('Origin')
        expect(body).to eq(['OK'])
      end
    end
  end
end
