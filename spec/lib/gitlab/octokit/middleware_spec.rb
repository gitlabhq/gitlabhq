require 'spec_helper'

describe Gitlab::Octokit::Middleware do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }

  shared_examples 'Public URL' do
    it 'does not raise an error' do
      expect(app).to receive(:call).with(env)

      expect { middleware.call(env) }.not_to raise_error
    end
  end

  shared_examples 'Local URL' do
    it 'raises an error' do
      expect { middleware.call(env) }.to raise_error(Gitlab::UrlBlocker::BlockedUrlError)
    end
  end

  describe '#call' do
    context 'when the URL is a public URL' do
      let(:env) { { url: 'https://public-url.com' } }

      it_behaves_like 'Public URL'
    end

    context 'when the URL is a localhost adresss' do
      let(:env) { { url: 'http://127.0.0.1' } }

      context 'when localhost requests are not allowed' do
        before do
          stub_application_setting(allow_local_requests_from_hooks_and_services: false)
        end

        it_behaves_like 'Local URL'
      end

      context 'when localhost requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_hooks_and_services: true)
        end

        it_behaves_like 'Public URL'
      end
    end

    context 'when the URL is a local network address' do
      let(:env) { { url: 'http://172.16.0.0' } }

      context 'when local network requests are not allowed' do
        before do
          stub_application_setting(allow_local_requests_from_hooks_and_services: false)
        end

        it_behaves_like 'Local URL'
      end

      context 'when local network requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_hooks_and_services: true)
        end

        it_behaves_like 'Public URL'
      end
    end
  end
end
