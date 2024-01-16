# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HTTP, feature_category: :shared do
  let(:default_options) do
    {
      allow_local_requests: false,
      deny_all_requests_except_allowed: false,
      dns_rebinding_protection_enabled: true,
      outbound_local_requests_allowlist: [],
      silent_mode_enabled: false
    }
  end

  describe '.get' do
    it 'calls Gitlab::HTTP_V2.get with default options' do
      expect(Gitlab::HTTP_V2).to receive(:get).with('/path', default_options)

      described_class.get('/path')
    end

    context 'when passing allow_object_storage:true' do
      before do
        allow(ObjectStoreSettings).to receive(:enabled_endpoint_uris).and_return([URI('http://example.com')])
      end

      it 'calls Gitlab::HTTP_V2.get with default options and extra_allowed_uris' do
        expect(Gitlab::HTTP_V2).to receive(:get)
          .with('/path', default_options.merge(extra_allowed_uris: [URI('http://example.com')]))

        described_class.get('/path', allow_object_storage: true)
      end
    end

    context 'when passing async:true' do
      it 'calls Gitlab::HTTP_V2.get with default options and async:true' do
        expect(Gitlab::HTTP_V2).to receive(:get)
          .with('/path', default_options.merge(async: true))

        described_class.get('/path', async: true)
      end

      it 'returns a Gitlab::HTTP_V2::LazyResponse object' do
        stub_request(:get, 'http://example.org').to_return(status: 200, body: 'hello world')
        result = described_class.get('http://example.org', async: true)

        expect(result).to be_a(Gitlab::HTTP_V2::LazyResponse)

        result.execute
        result.wait

        expect(result.value).to be_a(HTTParty::Response)
        expect(result.value.body).to eq('hello world')
      end

      context 'when there is a DB call in the concurrent thread' do
        before do
          # Simulating Sentry is active and configured.
          # More info: https://gitlab.com/gitlab-org/gitlab/-/issues/432145#note_1671305713
          stub_sentry_settings
          allow(Gitlab::ErrorTracking).to receive(:sentry_configurable?).and_return(true)
          Gitlab::ErrorTracking.configure
        end

        after do
          clear_sentry_settings
        end

        it 'raises Gitlab::Utils::ConcurrentRubyThreadIsUsedError error' do
          stub_request(:get, 'http://example.org').to_return(status: 200, body: 'hello world')

          result = described_class.get('http://example.org', async: true) do |_fragment|
            User.first
          end

          result.execute
          result.wait

          expect { result.value }.to raise_error(Gitlab::Utils::ConcurrentRubyThreadIsUsedError,
            "Cannot run 'db' if running from `Concurrent::Promise`.")
        end
      end
    end
  end

  describe '.try_get' do
    it 'calls .get' do
      expect(described_class).to receive(:get).with('/path', {})

      described_class.try_get('/path')
    end

    it 'returns nil when .get raises an error' do
      expect(described_class).to receive(:get).and_raise(SocketError)

      expect(described_class.try_get('/path')).to be_nil
    end
  end

  describe '.perform_request' do
    context 'when sending a GET request' do
      it 'calls Gitlab::HTTP_V2.get with default options' do
        expect(Gitlab::HTTP_V2).to receive(:get).with('/path', default_options)

        described_class.perform_request(Net::HTTP::Get, '/path', {})
      end
    end

    context 'when sending a LOCK request' do
      it 'raises ArgumentError' do
        expect do
          described_class.perform_request(Net::HTTP::Lock, '/path', {})
        end.to raise_error(ArgumentError, "Unsupported HTTP method: 'lock'.")
      end
    end
  end
end
