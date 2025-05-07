# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::Snowplow, :do_not_stub_snowplow_by_default do
  let(:emitter) { SnowplowTracker::Emitter.new(endpoint: 'localhost', options: { buffer_size: 1 }) }
  let(:event_eligibility_checker) { instance_double(Gitlab::Tracking::EventEligibilityChecker) }
  let(:event_eligible) { true }
  let(:tracker) do
    SnowplowTracker::Tracker.new(emitters: [emitter], subject: SnowplowTracker::Subject.new, namespace: 'namespace',
      app_id: 'app_id')
  end

  before do
    stub_application_setting(
      snowplow_enabled?: true,
      snowplow_collector_hostname: 'gitfoo.com',
      snowplow_app_id: '_abc123_'
    )

    allow(Kernel).to receive(:at_exit)
    allow(Gitlab::Tracking::EventEligibilityChecker).to receive(:new).and_return(event_eligibility_checker)
    allow(event_eligibility_checker).to receive(:eligible?).and_return(event_eligible)
  end

  around do |example|
    freeze_time { example.run }
  end

  context 'when in production environment' do
    before do
      allow(Rails.env).to receive_messages(
        development?: false,
        test?: false
      )
    end

    it "adds Kernel.at_exit hook" do
      subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)
      expect(Kernel).to have_received(:at_exit)
    end

    describe '#event' do
      context 'when event is eligible' do
        before do
          expect(SnowplowTracker::AsyncEmitter)
            .to receive(:new)
                  .with(endpoint: 'gitfoo.com',
                    options: { protocol: 'https',
                               method: 'post',
                               buffer_size: 10,
                               on_success: subject.method(:increment_successful_events_emissions),
                               on_failure: subject.method(:failure_callback) })
                  .and_return(emitter)

          expect(SnowplowTracker::Tracker)
            .to receive(:new)
                  .with(emitters: [emitter],
                    subject: an_instance_of(SnowplowTracker::Subject),
                    namespace: described_class::SNOWPLOW_NAMESPACE,
                    app_id: '_abc123_')
                  .and_return(tracker)

          allow(tracker).to receive(:track_struct_event).and_call_original
        end

        it 'sends event to tracker' do
          subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)

          expect(tracker)
            .to have_received(:track_struct_event)
                  .with(category: 'category', action: 'action', label: 'label', property: 'property', value: 1.5,
                    context: nil, tstamp: (Time.now.to_f * 1000).to_i)
        end

        it 'increase total snowplow events counter' do
          counter = double

          expect(counter).to receive(:increment)
          expect(Gitlab::Metrics).to receive(:counter)
                                       .with(:gitlab_snowplow_events_total,
                                         'Number of Snowplow events')
                                       .and_return(counter)

          subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)
        end
      end

      context 'when event is ineligible' do
        let(:event_eligible) { false }

        it 'does not sends event to tracker' do
          allow(tracker).to receive(:track_struct_event).and_call_original

          subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)

          expect(tracker).not_to have_received(:track_struct_event)
        end

        it 'does not increase total snowplow events counter' do
          expect(Gitlab::Metrics).not_to receive(:counter)

          subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)
        end
      end
    end
  end

  context "when in development or test environment" do
    it "initializes POST emitter with buffer_size 1" do
      allow(SnowplowTracker::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track_struct_event).and_call_original

      expect(SnowplowTracker::AsyncEmitter)
        .to receive(:new)
        .with(endpoint: 'gitfoo.com',
          options: { protocol: 'https',
                     method: 'post',
                     buffer_size: 1,
                     on_success: subject.method(:increment_successful_events_emissions),
                     on_failure: subject.method(:failure_callback) })
        .and_return(emitter)

      subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)
    end

    it "doesn't add Kernel.at_exit hook" do
      expect(Kernel).not_to receive(:at_exit)

      subject
    end
  end

  context 'callbacks' do
    describe 'on success' do
      it 'increase gitlab_successful_snowplow_events_total counter' do
        counter = double

        expect(counter).to receive(:increment).with({}, 2)
        expect(Gitlab::Metrics).to receive(:counter)
                                     .with(:gitlab_snowplow_successful_events_total,
                                       'Number of successful Snowplow events emissions')
                                     .and_return(counter)

        subject.method(:increment_successful_events_emissions).call(2)
      end
    end

    describe 'on failure' do
      it 'increase gitlab_failed_snowplow_events_total counter and logs failures', :aggregate_failures do
        counter = double
        error_message = "Admin::AuditLogsController search_audit_event failed to be reported to collector at gitfoo.com"
        failures = [{ "e" => "se",
                      "se_ca" => "Admin::AuditLogsController",
                      "se_ac" => "search_audit_event" }]
        allow(Gitlab::Metrics).to receive(:counter)
                                    .with(:gitlab_snowplow_successful_events_total,
                                      'Number of successful Snowplow events emissions')
                                    .and_call_original

        expect(Gitlab::AppLogger).to receive(:error).with(error_message)
        expect(counter).to receive(:increment).with({}, 1)
        expect(Gitlab::Metrics).to receive(:counter)
                                     .with(:gitlab_snowplow_failed_events_total,
                                       'Number of failed Snowplow events emissions')
                                     .and_return(counter)

        subject.method(:failure_callback).call(2, failures)
      end
    end
  end

  describe '#emit_event_payload' do
    let(:payload) { { "event" => "page_view", "user_id" => "123" } }

    before do
      allow(SnowplowTracker::AsyncEmitter).to receive(:new).and_return(emitter)
    end

    it "forwards the payload to the emitter" do
      expect(emitter).to receive(:input).with(payload)
      subject.emit_event_payload(payload)
    end
  end

  describe '#frontend_client_options' do
    let_it_be(:group) { create(:group) }

    context 'when snowplow is enabled' do
      before do
        stub_application_setting(snowplow_enabled?: true)
        stub_feature_flags(additional_snowplow_tracking: true)
      end

      it 'returns snowplow options' do
        expected = {
          namespace: 'gl',
          hostname: 'gitfoo.com',
          cookieDomain: nil,
          appId: '_abc123_',
          formTracking: true,
          linkClickTracking: true
        }

        expect(subject.frontend_client_options(group)).to eq(expected)
      end
    end

    context 'when snowplow is disabled' do
      before do
        stub_application_setting(snowplow_enabled?: false, snowplow_app_id: nil)

        allow(Gitlab).to receive(:host_with_port).and_return('gitlab.example.com')
        allow(Gitlab.config.gitlab).to receive(:https).and_return(true)
        allow(Rails.application.routes.url_helpers).to receive(:event_forwarding_path).and_return('/events')
      end

      it 'returns product_usage_events options' do
        expected = {
          namespace: 'gl',
          hostname: 'gitlab.example.com',
          postPath: '/events',
          forceSecureTracker: true,
          appId: 'gitlab_sm'
        }

        expect(subject.frontend_client_options(group)).to eq(expected)
      end
    end
  end

  describe '#enabled?' do
    context 'when snowplow is enabled' do
      before do
        stub_application_setting(snowplow_enabled?: true)
      end

      it 'returns true' do
        expect(subject.enabled?).to be_truthy
      end
    end

    context 'when snowplow is disabled' do
      before do
        stub_application_setting(snowplow_enabled?: false)
      end

      context 'and collect_product_usage_events is enabled' do
        it 'returns true' do
          expect(subject.enabled?).to be_truthy
        end
      end

      context 'and collect_product_usage_events is disabled' do
        before do
          stub_feature_flags(collect_product_usage_events: false)
        end

        it 'returns false' do
          expect(subject.enabled?).to be_falsey
        end
      end
    end
  end

  describe '#hostname' do
    context 'when snowplow is enabled' do
      before do
        stub_application_setting(snowplow_enabled?: true)
      end

      it 'returns snowplow_collector_hostname' do
        expect(subject.hostname).to eq('gitfoo.com')
      end
    end

    context 'when snowplow is disabled' do
      before do
        stub_application_setting(snowplow_enabled?: false)
        stub_feature_flags(use_staging_endpoint_for_product_usage_events: enable_stg_events)
      end

      context "with use_staging_endpoint_for_product_usage_events FF disabled" do
        let(:enable_stg_events) { false }

        it 'returns product usage event collection hostname' do
          expect(subject.hostname).to eq('events.gitlab.net')
        end
      end

      context "with use_staging_endpoint_for_product_usage_events FF enabled" do
        let(:enable_stg_events) { true }

        it 'returns product usage event collection hostname' do
          expect(subject.hostname).to eq('events-stg.gitlab.net')
        end
      end
    end

    describe '#app_id' do
      subject { described_class.new.app_id }

      context 'when snowplow is enabled' do
        before do
          stub_application_setting(snowplow_enabled?: true)
        end

        it { is_expected.to eq('_abc123_') }
      end

      context 'when snowplow is disabled' do
        before do
          stub_application_setting(snowplow_enabled?: false)
          stub_application_setting(gitlab_dedicated_instance?: dedicated_instance)
        end

        context 'when dedicated instance' do
          let(:dedicated_instance) { true }

          it { is_expected.to eq('gitlab_dedicated') }
        end

        context 'when self-hosted instance' do
          let(:dedicated_instance) { false }

          it { is_expected.to eq('gitlab_sm') }
        end
      end
    end
  end

  describe 'emitter class' do
    context 'when snowplow is enabled' do
      before do
        stub_application_setting(snowplow_enabled?: true)
      end

      it 'uses AsyncEmitter' do
        expect(SnowplowTracker::AsyncEmitter).to receive(:new)
        expect(Gitlab::Tracking::SnowplowLoggingEmitter).not_to receive(:new)

        subject.send(:emitter)
      end
    end

    context 'when snowplow is disabled' do
      before do
        stub_application_setting(snowplow_enabled?: false)
      end

      context 'when GITLAB_DISABLE_PRODUCT_USAGE_EVENT_LOGGING env variable is true' do
        it 'uses AsyncEmitter' do
          stub_env('GITLAB_DISABLE_PRODUCT_USAGE_EVENT_LOGGING', '1')

          expect(SnowplowTracker::AsyncEmitter).to receive(:new)
          expect(Gitlab::Tracking::SnowplowLoggingEmitter).not_to receive(:new)

          subject.send(:emitter)
        end
      end

      context 'when GITLAB_DISABLE_PRODUCT_USAGE_EVENT_LOGGING env variable is falsey' do
        it 'uses SnowplowLoggingEmitter' do
          stub_env('GITLAB_DISABLE_PRODUCT_USAGE_EVENT_LOGGING', 'false')

          expect(SnowplowTracker::AsyncEmitter).not_to receive(:new)
          expect(Gitlab::Tracking::SnowplowLoggingEmitter).to receive(:new)

          subject.send(:emitter)
        end
      end

      context 'when GITLAB_DISABLE_PRODUCT_USAGE_EVENT_LOGGING env variable is not set' do
        it 'uses SnowplowLoggingEmitter' do
          expect(SnowplowTracker::AsyncEmitter).not_to receive(:new)
          expect(Gitlab::Tracking::SnowplowLoggingEmitter).to receive(:new)

          subject.send(:emitter)
        end
      end
    end
  end
end
