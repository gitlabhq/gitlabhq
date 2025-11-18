# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::Snowplow, :do_not_stub_snowplow_by_default, feature_category: :application_instrumentation do
  let(:emitter) { SnowplowTracker::Emitter.new(endpoint: 'localhost', options: { buffer_size: 1 }) }
  let(:event_eligibility_checker) { instance_double(Gitlab::Tracking::EventEligibilityChecker) }
  let(:event_eligible) { true }
  let(:track_struct_event_logger) { false }
  let(:tracker) do
    SnowplowTracker::Tracker.new(emitters: [emitter], subject: SnowplowTracker::Subject.new, namespace: 'namespace',
      app_id: 'app_id')
  end

  before do
    stub_feature_flags(track_struct_event_logger: track_struct_event_logger)
    stub_application_setting(
      snowplow_enabled?: true,
      snowplow_collector_hostname: 'gitfoo.com',
      snowplow_app_id: '_abc123_'
    )

    allow(Gitlab::Tracking::EventEligibilityChecker).to receive(:new).and_return(event_eligibility_checker)
    allow(event_eligibility_checker).to receive(:eligible?).and_return(event_eligible)
  end

  around do |example|
    freeze_time { example.run }
  end

  context 'when not in test environment' do
    before do
      allow(Rails.env).to receive(:test?).and_return(false)
    end

    describe '#event' do
      context 'when event is eligible' do
        before do
          allow_next_instance_of(Gitlab::Tracking::Destinations::DestinationConfiguration) do |config|
            allow(config).to receive_messages(hostname: 'gitfoo.com', protocol: 'https')
          end

          expect(SnowplowTracker::AsyncEmitter)
            .to receive(:new)
                  .with(endpoint: 'gitfoo.com',
                    options: { protocol: 'https',
                               method: 'post',
                               buffer_size: 1,
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

    it "initializes POST emitter with buffer_size 1" do
      allow(SnowplowTracker::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track_struct_event).and_call_original

      allow_next_instance_of(Gitlab::Tracking::Destinations::DestinationConfiguration) do |config|
        allow(config).to receive_messages(hostname: 'gitfoo.com', protocol: 'https')
      end

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
      allow(Gitlab::Tracking::SnowplowTestEmitter).to receive(:new).and_return(emitter)
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
      end

      shared_examples 'hostname with staging' do |staging_env, host, expected_endpoint|
        context "when staging_env=#{staging_env}, host=#{host}" do
          before do
            allow(Gitlab).to receive(:staging?).and_return(staging_env)
            stub_config_setting(host: host) if host
          end

          it "returns #{expected_endpoint}" do
            expect(subject.hostname).to eq(expected_endpoint)
          end
        end
      end

      it_behaves_like 'hostname with staging', true, nil, 'events-stg.gitlab.net'
      it_behaves_like 'hostname with staging', false, 'gitlab-test.example.test', 'events-stg.gitlab.net'
      it_behaves_like 'hostname with staging', false, 'example.com', 'events.gitlab.net'
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

      shared_examples 'app_id with staging' do |instance_type, staging_env, host, expected_app_id|
        context "when #{instance_type}, staging_env=#{staging_env}, host=#{host}" do
          let(:dedicated_instance) { instance_type == 'dedicated' }

          before do
            allow(Gitlab).to receive(:staging?).and_return(staging_env)
            stub_config_setting(host: host) if host
          end

          it { is_expected.to eq(expected_app_id) }
        end
      end

      # Dedicated instance tests
      it_behaves_like 'app_id with staging', 'dedicated', false, 'example.com', 'gitlab_dedicated'
      it_behaves_like 'app_id with staging', 'dedicated', true, nil, 'gitlab_dedicated_staging'
      it_behaves_like 'app_id with staging', 'dedicated', false, 'gitlab-test.example.test',
        'gitlab_dedicated_staging'

      # Self-hosted instance tests
      it_behaves_like 'app_id with staging', 'self-hosted', false, 'example.com', 'gitlab_sm'
      it_behaves_like 'app_id with staging', 'self-hosted', true, nil, 'gitlab_sm_staging'
      it_behaves_like 'app_id with staging', 'self-hosted', false, 'gitlab-test.example.test', 'gitlab_sm_staging'

      context 'when self-hosted instance' do
        let(:dedicated_instance) { false }

        it { is_expected.to eq('gitlab_sm') }
      end
    end
  end

  describe 'emitter class' do
    context 'when snowplow is enabled' do
      before do
        stub_application_setting(snowplow_enabled?: true)
        allow(Rails.env).to receive(:test?).and_return(false)
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
        allow(Rails.env).to receive(:test?).and_return(false)
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

    context 'in test environment' do
      it 'uses SnowplowTestEmitter to prevent HTTP requests' do
        # In test environment, we expect SnowplowTestEmitter to prevent HTTP requests
        expect(Gitlab::Tracking::SnowplowTestEmitter).to receive(:new)
        expect(SnowplowTracker::AsyncEmitter).not_to receive(:new)
        expect(Gitlab::Tracking::SnowplowLoggingEmitter).not_to receive(:new)
        subject.send(:emitter)
      end
    end
  end
end
