# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::StaticAssetsAuthorization, feature_category: :web_ide do
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
    context 'when request is for non-protected asset paths' do
      let(:path_info) { '/assets/application.js' }

      context 'with GET request' do
        let(:request_method) { 'GET' }
        let(:origin_header) { 'https://abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }

        it 'passes through without adding special headers' do
          status, headers, body = middleware.call(env)

          expect(status).to eq(200)
          expect(headers['Access-Control-Allow-Origin']).to be_nil
          expect(headers['Access-Control-Allow-Methods']).to be_nil
          expect(headers['Vary']).to be_nil
          expect(headers['Cross-Origin-Opener-Policy']).to be_nil
          expect(headers['Cross-Origin-Resource-Policy']).to be_nil
          expect(headers['Content-Security-Policy']).to be_nil
          expect(body).to eq(['OK'])
        end
      end

      context 'with OPTIONS request' do
        let(:request_method) { 'OPTIONS' }
        let(:origin_header) { 'https://abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }

        it 'returns empty response without special headers' do
          expect(app).not_to receive(:call)

          status, headers, body = middleware.call(env)

          expect(status).to eq(204)
          expect(headers).to be_empty
          expect(body).to eq([])
        end
      end
    end

    context 'when request is for protected asset directories' do
      let(:gitlab_url) { 'http://localhost:3000' }

      before do
        allow(Gitlab.config.gitlab).to receive(:url).and_return(gitlab_url)
      end

      shared_examples 'applies security headers to protected paths' do
        context 'when Origin header matches extension host domain' do
          let(:origin_header) { 'https://abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }

          context 'with OPTIONS request' do
            let(:request_method) { 'OPTIONS' }

            it 'includes both CORS and security headers without calling app' do
              expect(app).not_to receive(:call)

              status, headers, body = middleware.call(env)

              expect(status).to eq(204)
              expect(headers['Access-Control-Allow-Origin']).to eq(origin_header)
              expect(headers['Access-Control-Allow-Methods']).to eq('GET, HEAD, OPTIONS')
              expect(headers['Vary']).to eq('Origin')
              expect(headers['Cross-Origin-Opener-Policy']).to eq('same-origin')
              expect(headers['Cross-Origin-Resource-Policy']).to eq('same-site')
              expect(headers['Content-Security-Policy']).to eq(
                "frame-ancestors 'self' https://*.#{extension_host_domain} #{gitlab_url};"
              )
              expect(body).to eq([])
            end
          end

          %w[GET HEAD].each do |method|
            context "with #{method} request" do
              let(:request_method) { method }

              it 'includes both CORS and security headers' do
                status, headers, body = middleware.call(env)

                expect(status).to eq(200)
                expect(headers['Access-Control-Allow-Origin']).to eq(origin_header)
                expect(headers['Access-Control-Allow-Methods']).to eq('GET, HEAD, OPTIONS')
                expect(headers['Vary']).to eq('Origin')
                expect(headers['Cross-Origin-Opener-Policy']).to eq('same-origin')
                expect(headers['Cross-Origin-Resource-Policy']).to eq('same-site')
                expect(headers['Content-Security-Policy']).to eq(
                  "frame-ancestors 'self' https://*.#{extension_host_domain} #{gitlab_url};"
                )
                expect(body).to eq(['OK'])
              end

              it 'merges with app response headers' do
                app_headers = {
                  'Content-Type' => 'application/javascript',
                  'Cache-Control' => 'public, max-age=3600'
                }
                allow(app).to receive(:call).with(env).and_return([200, app_headers, ['OK']])

                status, headers, body = middleware.call(env)

                expect(status).to eq(200)
                expect(headers['Content-Type']).to eq('application/javascript')
                expect(headers['Cache-Control']).to eq('public, max-age=3600')
                expect(headers['Access-Control-Allow-Origin']).to eq(origin_header)
                expect(headers['Cross-Origin-Opener-Policy']).to eq('same-origin')
                expect(body).to eq(['OK'])
              end
            end
          end
        end

        context 'when Origin header does not match extension host domain' do
          let(:origin_header) { 'https://evil.com' }
          let(:request_method) { 'GET' }

          it 'includes only security headers, not CORS headers' do
            status, headers, body = middleware.call(env)

            expect(status).to eq(200)
            expect(headers['Access-Control-Allow-Origin']).to be_nil
            expect(headers['Access-Control-Allow-Methods']).to be_nil
            expect(headers['Vary']).to be_nil
            expect(headers['Cross-Origin-Opener-Policy']).to eq('same-origin')
            expect(headers['Cross-Origin-Resource-Policy']).to eq('same-site')
            expect(headers['Content-Security-Policy']).to eq(
              "frame-ancestors 'self' https://*.#{extension_host_domain} #{gitlab_url};"
            )
            expect(body).to eq(['OK'])
          end
        end

        context 'when Origin header is not present' do
          let(:origin_header) { nil }
          let(:request_method) { 'GET' }

          it 'includes only security headers, not CORS headers' do
            status, headers, body = middleware.call(env)

            expect(status).to eq(200)
            expect(headers['Access-Control-Allow-Origin']).to be_nil
            expect(headers['Access-Control-Allow-Methods']).to be_nil
            expect(headers['Vary']).to be_nil
            expect(headers['Cross-Origin-Opener-Policy']).to eq('same-origin')
            expect(headers['Cross-Origin-Resource-Policy']).to eq('same-site')
            expect(headers['Content-Security-Policy']).to eq(
              "frame-ancestors 'self' https://*.#{extension_host_domain} #{gitlab_url};"
            )
            expect(body).to eq(['OK'])
          end
        end
      end

      context 'with gitlab-web-ide-vscode-workbench paths' do
        [
          '/assets/webpack/gitlab-web-ide-vscode-workbench/index.html',
          '/assets/webpack/gitlab-web-ide-vscode-workbench/vs/editor/editor.main.js'
        ].each do |protected_path|
          context "with path #{protected_path}" do
            let(:path_info) { protected_path }

            include_examples 'applies security headers to protected paths'
          end
        end
      end

      context 'with gitlab-mono paths' do
        let(:path_info) { '/assets/gitlab-mono/file.js' }

        include_examples 'applies security headers to protected paths'
      end
    end

    context 'when request method is not GET, HEAD, or OPTIONS' do
      let(:path_info) { '/assets/webpack/gitlab-web-ide-vscode-workbench/index.html' }
      let(:request_method) { 'POST' }
      let(:origin_header) { 'https://abcdefghijklmnopqrstuvwxyz1234.cdn.web-ide.gitlab-static.net' }

      it 'passes through without handling' do
        expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers['Access-Control-Allow-Origin']).to be_nil
        expect(body).to eq(['OK'])
      end
    end
  end
end
