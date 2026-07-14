# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::BillingAuthEmitter, feature_category: :application_instrumentation do
  subject(:emitter) do
    described_class.new(
      endpoint: 'billing.stgsub.gitlab.net',
      options: { protocol: 'https', method: 'post', buffer_size: 1, path: path }
    )
  end

  let(:path) { '/com.snowplowanalytics.snowplow.auth/tp2' }
  let(:collector_uri) { "https://billing.stgsub.gitlab.net#{path}" }
  let(:payload) { { 'key' => 'value' } }
  let(:token_source) { instance_double(Gitlab::Tracking::Destinations::BillingOidcTokenSource) }
  let(:token) { 'oidc-id-token' }

  before do
    allow(Gitlab::Tracking::Destinations::BillingOidcTokenSource)
      .to receive(:new).with('billing.stgsub.gitlab.net').and_return(token_source)
    allow(token_source).to receive(:token).and_return(token)

    stub_request(:post, collector_uri).to_return(status: 200, body: '')
  end

  describe '#http_post' do
    it 'posts to the authenticated collector path with the Authorization Bearer header' do
      emitter.send(:http_post, payload)

      expect(
        a_request(:post, collector_uri).with(
          headers: { 'Authorization' => "Bearer #{token}" },
          body: payload.to_json
        )
      ).to have_been_made.once
    end

    it 'memoizes a single token source across requests' do
      3.times { emitter.send(:http_post, payload) }

      expect(Gitlab::Tracking::Destinations::BillingOidcTokenSource)
        .to have_received(:new).with('billing.stgsub.gitlab.net').once
    end

    it 'sends the request through Gitlab::HTTP with timeouts' do
      expect(Gitlab::HTTP).to receive(:post).with(
        collector_uri,
        hash_including(open_timeout: described_class::HTTP_TIMEOUT, read_timeout: described_class::HTTP_TIMEOUT)
      ).and_call_original

      emitter.send(:http_post, payload)
    end

    context 'when no token is available' do
      let(:token) { nil }

      it 'sends the request without an Authorization header and logs a warning' do
        expect(emitter.logger).to receive(:warn).with(/no OIDC token available/)

        emitter.send(:http_post, payload)

        expect(
          a_request(:post, collector_uri)
            .with { |req| !req.headers.key?('Authorization') }
        ).to have_been_made.once
      end
    end
  end
end
