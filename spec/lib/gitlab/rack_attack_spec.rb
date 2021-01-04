# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack, :aggregate_failures do
  describe '.configure' do
    let(:fake_rack_attack) { class_double("Rack::Attack") }
    let(:fake_rack_attack_request) { class_double("Rack::Attack::Request") }

    let(:throttles) do
      {
        throttle_unauthenticated: Gitlab::Throttle.unauthenticated_options,
        throttle_authenticated_api: Gitlab::Throttle.authenticated_api_options,
        throttle_product_analytics_collector: { limit: 100, period: 60 },
        throttle_unauthenticated_protected_paths: Gitlab::Throttle.unauthenticated_options,
        throttle_authenticated_protected_paths_api: Gitlab::Throttle.authenticated_api_options,
        throttle_authenticated_protected_paths_web: Gitlab::Throttle.authenticated_web_options
      }
    end

    before do
      stub_const("Rack::Attack", fake_rack_attack)
      stub_const("Rack::Attack::Request", fake_rack_attack_request)

      allow(fake_rack_attack).to receive(:throttled_response=)
      allow(fake_rack_attack).to receive(:throttle)
      allow(fake_rack_attack).to receive(:track)
      allow(fake_rack_attack).to receive(:safelist)
      allow(fake_rack_attack).to receive(:blocklist)
    end

    it 'extends the request class' do
      described_class.configure(fake_rack_attack)

      expect(fake_rack_attack_request).to include(described_class::Request)
    end

    it 'configures the throttle response' do
      described_class.configure(fake_rack_attack)

      expect(fake_rack_attack).to have_received(:throttled_response=).with(an_instance_of(Proc))
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
      regular_throttles = throttles.keys[2..-1]
      stub_env('GITLAB_THROTTLE_DRY_RUN', dry_run_throttles.join(','))

      described_class.configure(fake_rack_attack)

      dry_run_throttles.each do |throttle|
        expect(fake_rack_attack).to have_received(:track).with(throttle.to_s, throttles[throttle])
      end
      regular_throttles.each do |throttle|
        expect(fake_rack_attack).to have_received(:throttle).with(throttle.to_s, throttles[throttle])
      end
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
