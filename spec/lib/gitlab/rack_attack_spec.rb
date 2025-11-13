# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack, :aggregate_failures, feature_category: :rate_limiting do
  describe '.configure' do
    let(:fake_rack_attack) { class_double("Rack::Attack") }
    let(:fake_rack_attack_request) { class_double(Rack::Attack::Request) }
    let(:fake_cache) { instance_double(Rack::Attack::Cache) }

    let(:throttles) do
      {
        throttle_unauthenticated_api: Gitlab::Throttle.options(:api, authenticated: false),
        throttle_authenticated_api: Gitlab::Throttle.options(:api, authenticated: true),
        throttle_unauthenticated_web: Gitlab::Throttle.unauthenticated_web_options,
        throttle_authenticated_web: Gitlab::Throttle.authenticated_web_options,
        throttle_product_analytics_collector: { limit: 100, period: 60 },
        throttle_unauthenticated_protected_paths: Gitlab::Throttle.protected_paths_options,
        throttle_authenticated_protected_paths_api: Gitlab::Throttle.protected_paths_options,
        throttle_authenticated_protected_paths_web: Gitlab::Throttle.protected_paths_options,
        throttle_unauthenticated_packages_api: Gitlab::Throttle.options(:packages_api, authenticated: false),
        throttle_authenticated_packages_api: Gitlab::Throttle.options(:packages_api, authenticated: true),
        throttle_authenticated_git_lfs: Gitlab::Throttle.throttle_authenticated_git_lfs_options,
        throttle_unauthenticated_files_api: Gitlab::Throttle.options(:files_api, authenticated: false),
        throttle_authenticated_files_api: Gitlab::Throttle.options(:files_api, authenticated: true),
        throttle_authenticated_git_http: Gitlab::Throttle.throttle_authenticated_git_http_options
      }
    end

    before do
      allow(fake_rack_attack).to receive(:throttled_responder=)
      allow(fake_rack_attack).to receive(:throttle)
      allow(fake_rack_attack).to receive(:track)
      allow(fake_rack_attack).to receive(:safelist)
      allow(fake_rack_attack).to receive(:blocklist)
      allow(fake_rack_attack).to receive(:cache).and_return(fake_cache)
      allow(fake_cache).to receive(:store=)

      fake_rack_attack.const_set(:Request, fake_rack_attack_request)
      stub_const("Rack::Attack", fake_rack_attack)
    end

    it 'extends the request class' do
      described_class.configure(fake_rack_attack)

      expect(fake_rack_attack_request).to include(described_class::Request)
    end

    it 'configures the throttle response' do
      described_class.configure(fake_rack_attack)

      expect(fake_rack_attack).to have_received(:throttled_responder=).with(an_instance_of(Proc))
    end

    describe 'throttled_responder' do
      let(:request) { instance_double(Rack::Request, env: env) }
      let(:env) do
        {
          'rack.attack.matched' => 'throttle_unauthenticated',
          'rack.attack.match_data' => { some: 'data' }
        }
      end

      let(:responder) do
        captured_proc = nil
        allow(fake_rack_attack).to receive(:throttled_responder=) do |proc|
          captured_proc = proc
        end
        described_class.configure(fake_rack_attack)
        captured_proc
      end

      context 'when RequestThrottleData.from_rack_attack returns valid data' do
        let(:throttle_data) { instance_double(described_class::RequestThrottleData) }
        let(:headers) do
          {
            'RateLimit-Name' => 'throttle_unauthenticated',
            'RateLimit-Limit' => '60',
            'Retry-After' => '1830'
          }
        end

        before do
          allow(described_class::RequestThrottleData).to receive(:from_rack_attack)
            .with('throttle_unauthenticated', { some: 'data' })
            .and_return(throttle_data)
          allow(throttle_data).to receive(:throttled_response_headers).and_return(headers)
        end

        it 'returns 429 status with rate limit headers' do
          status, response_headers, body = responder.call(request)

          expect(status).to eq(429)
          expect(response_headers).to include(headers)
          expect(response_headers['Content-Type']).to eq('text/plain')
          expect(body).to eq([Gitlab::Throttle.rate_limiting_response_text])
        end
      end

      context 'when RequestThrottleData.from_rack_attack returns nil' do
        before do
          allow(described_class::RequestThrottleData).to receive(:from_rack_attack)
            .with('throttle_unauthenticated', { some: 'data' })
            .and_return(nil)
        end

        it 'returns 429 status without rate limit headers' do
          status, response_headers, body = responder.call(request)

          expect(status).to eq(429)
          expect(response_headers).to eq({ 'Content-Type' => 'text/plain' })
          expect(response_headers).not_to have_key('RateLimit-Name')
          expect(response_headers).not_to have_key('Retry-After')
          expect(body).to eq([Gitlab::Throttle.rate_limiting_response_text])
        end
      end
    end

    it 'configures the safelist' do
      described_class.configure(fake_rack_attack)

      expect(fake_rack_attack).to have_received(:safelist).with('throttle_bypass_header')
    end

    it 'configures throttles if no dry-run was configured' do
      described_class.configure(fake_rack_attack)

      throttles.each do |throttle, options|
        expect(fake_rack_attack).to have_received(:throttle).with(throttle.to_s, options)
      end
    end

    it 'configures tracks if dry-run was configured for all throttles' do
      stub_env('GITLAB_THROTTLE_DRY_RUN', '*')

      described_class.configure(fake_rack_attack)

      throttles.each do |throttle, options|
        expect(fake_rack_attack).to have_received(:track).with(throttle.to_s, options)
      end
      expect(fake_rack_attack).not_to have_received(:throttle)
    end

    it 'configures tracks and throttles with a selected set of dry-runs' do
      dry_run_throttles = throttles.each_key.first(2)
      regular_throttles = throttles.keys[2..]
      stub_env('GITLAB_THROTTLE_DRY_RUN', dry_run_throttles.join(','))

      described_class.configure(fake_rack_attack)

      dry_run_throttles.each do |throttle|
        expect(fake_rack_attack).to have_received(:track).with(throttle.to_s, throttles[throttle])
      end
      regular_throttles.each do |throttle|
        expect(fake_rack_attack).to have_received(:throttle).with(throttle.to_s, throttles[throttle])
      end
    end

    it 'enables dry-runs for `throttle_unauthenticated_api` and `throttle_unauthenticated_web` when selecting `throttle_unauthenticated`' do
      stub_env('GITLAB_THROTTLE_DRY_RUN', 'throttle_unauthenticated')

      described_class.configure(fake_rack_attack)

      expect(fake_rack_attack).to have_received(:track).with('throttle_unauthenticated_api', throttles[:throttle_unauthenticated_api])
      expect(fake_rack_attack).to have_received(:track).with('throttle_unauthenticated_web', throttles[:throttle_unauthenticated_web])
    end

    context 'user allowlist' do
      subject { described_class.user_allowlist }

      it 'is empty' do
        described_class.configure(fake_rack_attack)

        expect(subject).to be_empty
      end

      it 'reflects GITLAB_THROTTLE_USER_ALLOWLIST' do
        stub_env('GITLAB_THROTTLE_USER_ALLOWLIST', '123,456')
        described_class.configure(fake_rack_attack)

        expect(subject).to contain_exactly(123, 456)
      end
    end
  end
end
