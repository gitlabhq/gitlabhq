# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::Snowplow, :do_not_stub_snowplow_by_default do
  let(:emitter) { SnowplowTracker::Emitter.new(endpoint: 'localhost', options: { buffer_size: 1 }) }
  let(:tracker) do
    SnowplowTracker::Tracker.new(emitters: [emitter], subject: SnowplowTracker::Subject.new, namespace: 'namespace',
      app_id: 'app_id')
  end

  before do
    stub_application_setting(
      snowplow_collector_hostname: 'gitfoo.com',
      snowplow_app_id: '_abc123_',
      snowplow_enabled: true
    )

    allow(Kernel).to receive(:at_exit)
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
    end

    it "adds Kernel.at_exit hook" do
      subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)
      expect(Kernel).to have_received(:at_exit)
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

  context 'when snowplow is disabled' do
    describe '#event' do
      it 'does not send event to tracker' do
        stub_application_setting(snowplow_enabled: false)

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
end
