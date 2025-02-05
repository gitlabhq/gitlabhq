# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::Snowplow, :do_not_stub_snowplow_by_default do
  let(:emitter) { SnowplowTracker::Emitter.new(endpoint: 'localhost', options: { buffer_size: 1 }) }
  let(:tracker) do
    SnowplowTracker::Tracker.new(emitters: [emitter], subject: SnowplowTracker::Subject.new, namespace: 'namespace',
      app_id: 'app_id')
  end

  before do
    stub_application_setting(snowplow_collector_hostname: 'gitfoo.com')
    stub_application_setting(snowplow_app_id: '_abc123_')
  end

  around do |example|
    freeze_time { example.run }
  end

  context 'when snowplow is enabled and POST is enabled' do
    before do
      stub_application_setting(snowplow_enabled: true)
      stub_feature_flags(snowplow_tracking_post_method: true)

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
    end

    describe '#event' do
      it 'sends event to tracker' do
        allow(tracker).to receive(:track_struct_event).and_call_original

        subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)

        expect(tracker)
          .to have_received(:track_struct_event)
          .with(category: 'category', action: 'action', label: 'label', property: 'property', value: 1.5, context: nil,
            tstamp: (Time.now.to_f * 1000).to_i)
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
  end

  context "when snowplow POST is disabled" do
    it "initializes emitter without specifying the method" do
      stub_application_setting(snowplow_enabled: true)
      stub_feature_flags(snowplow_tracking_post_method: false)

      allow(SnowplowTracker::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track_struct_event).and_call_original

      expect(SnowplowTracker::AsyncEmitter)
        .to receive(:new)
        .with(endpoint: 'gitfoo.com',
          options: { protocol: 'https',
                     on_success: subject.method(:increment_successful_events_emissions),
                     on_failure: subject.method(:failure_callback) })
        .and_return(emitter)

      subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)
    end
  end

  context 'when snowplow is not enabled' do
    describe '#event' do
      it 'does not send event to tracker' do
        expect_any_instance_of(SnowplowTracker::Tracker).not_to receive(:track_struct_event)

        subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)
      end
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
end
