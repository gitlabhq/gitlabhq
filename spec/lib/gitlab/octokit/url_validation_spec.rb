# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Octokit::UrlValidation, feature_category: :importers do
  let(:app) { instance_double(Octokit::Response::RaiseError) }
  let(:middleware) { described_class.new(app) }

  subject(:call_middleware) { middleware.call(env) }

  shared_examples 'Allowed URL' do
    it 'does not raise an error' do
      expect(app).to receive(:call).with(env)

      expect { call_middleware }.not_to raise_error
    end
  end

  shared_examples 'Blocked URL' do
    it 'raises an error' do
      expect { call_middleware }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
    end
  end

  describe '#call' do
    context 'when the URL is a public URL' do
      let(:env) { { url: 'https://public-url.com' } }

      it_behaves_like 'Allowed URL'

      context 'when DNS rebinding protection is active' do
        before do
          stub_application_setting(dns_rebinding_protection_enabled: true)
        end

        it 'calls validate! with dns_rebind_protection: true' do
          expect(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!).with(
            'https://public-url.com',
            hash_including(dns_rebind_protection: true)
          ).and_call_original

          expect(app).to receive(:call).with(env)

          call_middleware
        end
      end

      context 'when behind an HTTP proxy' do
        before do
          allow(Gitlab).to receive(:http_proxy_env?).and_return(true)
        end

        it 'disables dns_rebind_protection' do
          expect(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!).with(
            'https://public-url.com',
            hash_including(dns_rebind_protection: false)
          ).and_call_original

          expect(app).to receive(:call).with(env)

          call_middleware
        end
      end

      context 'with failed address check' do
        before do
          allow(Addrinfo).to receive(:getaddrinfo)
            .with('public-url.com', anything, anything, :STREAM, any_args)
            .and_raise(SocketError)
        end

        it_behaves_like 'Blocked URL'

        context 'with disabled dns rebinding check' do
          before do
            stub_application_setting(dns_rebinding_protection_enabled: false)
          end

          it_behaves_like 'Allowed URL'
        end
      end
    end

    context 'when the URL is a localhost address' do
      let(:env) { { url: 'http://127.0.0.1' } }

      context 'when localhost requests are not allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
        end

        it_behaves_like 'Blocked URL'
      end

      context 'when localhost requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it_behaves_like 'Allowed URL'
      end
    end

    context 'when the URL is a local network address' do
      let(:env) { { url: 'http://172.16.0.0' } }

      context 'when local network requests are not allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
        end

        it_behaves_like 'Blocked URL'
      end

      context 'when local network requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it_behaves_like 'Allowed URL'
      end
    end

    context 'when a non HTTP/HTTPS URL is provided' do
      let(:env) { { url: 'ssh://172.16.0.0' } }

      it 'raises an error' do
        expect { call_middleware }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
      end
    end
  end
end
