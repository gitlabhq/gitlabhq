# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::Snowplow do
  let(:emitter) { SnowplowTracker::Emitter.new('localhost', buffer_size: 1) }
  let(:tracker) { SnowplowTracker::Tracker.new(emitter, SnowplowTracker::Subject.new, 'namespace', 'app_id') }

  before do
    stub_application_setting(snowplow_collector_hostname: 'gitfoo.com')
    stub_application_setting(snowplow_app_id: '_abc123_')
  end

  around do |example|
    freeze_time { example.run }
  end

  context 'when snowplow is enabled' do
    before do
      stub_application_setting(snowplow_enabled: true)

      expect(SnowplowTracker::AsyncEmitter)
        .to receive(:new)
        .with('gitfoo.com',
              { protocol: 'https',
                on_success: subject.method(:increment_successful_events_emissions),
                on_failure: subject.method(:failure_callback) })
        .and_return(emitter)

      expect(SnowplowTracker::Tracker)
        .to receive(:new)
        .with(emitter, an_instance_of(SnowplowTracker::Subject), Gitlab::Tracking::SNOWPLOW_NAMESPACE, '_abc123_')
        .and_return(tracker)
    end

    describe '#event' do
      it 'sends event to tracker' do
        allow(tracker).to receive(:track_struct_event).and_call_original

        subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)

        expect(tracker)
          .to have_received(:track_struct_event)
          .with('category', 'action', 'label', 'property', 1.5, nil, (Time.now.to_f * 1000).to_i)
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
