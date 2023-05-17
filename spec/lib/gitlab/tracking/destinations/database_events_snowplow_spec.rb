# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::DatabaseEventsSnowplow, :do_not_stub_snowplow_by_default, feature_category: :application_instrumentation do
  let(:emitter) { SnowplowTracker::Emitter.new(endpoint: 'localhost', options: { buffer_size: 1 }) }

  let(:tracker) do
    SnowplowTracker::Tracker
      .new(
        emitters: [emitter],
        subject: SnowplowTracker::Subject.new,
        namespace: 'namespace',
        app_id: 'app_id'
      )
  end

  before do
    stub_application_setting(snowplow_app_id: '_abc123_')
  end

  around do |example|
    freeze_time { example.run }
  end

  context 'when snowplow is enabled' do
    before do
      allow(SnowplowTracker::AsyncEmitter)
        .to receive(:new)
        .with(endpoint: endpoint,
          options:
            {
              protocol: 'https',
              on_success: subject.method(:increment_successful_events_emissions),
              on_failure: subject.method(:failure_callback)
            }
        ).and_return(emitter)

      allow(SnowplowTracker::Tracker)
        .to receive(:new)
              .with(
                emitters: [emitter],
                subject: an_instance_of(SnowplowTracker::Subject),
                namespace: described_class::SNOWPLOW_NAMESPACE,
                app_id: '_abc123_'
              ).and_return(tracker)
    end

    describe '#event' do
      let(:endpoint) { 'localhost:9091' }
      let(:event_params) do
        {
          category: 'category',
          action: 'action',
          label: 'label',
          property: 'property',
          value: 1.5,
          context: nil,
          tstamp: (Time.now.to_f * 1000).to_i
        }
      end

      context 'when on gitlab.com environment' do
        let(:endpoint) { 'db-snowplow.trx.gitlab.net' }

        it 'sends event to tracker' do
          allow(Gitlab).to receive(:com?).and_return(true)
          allow(tracker).to receive(:track_struct_event).and_call_original

          subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)

          expect(tracker).to have_received(:track_struct_event).with(event_params)
        end
      end

      it 'sends event to tracker' do
        allow(tracker).to receive(:track_struct_event).and_call_original

        subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)

        expect(tracker).to have_received(:track_struct_event).with(event_params)
      end

      it 'increase total snowplow events counter' do
        counter = double

        expect(counter).to receive(:increment)
        expect(Gitlab::Metrics).to receive(:counter)
                                     .with(:gitlab_db_events_snowplow_events_total, 'Number of Snowplow events')
                                     .and_return(counter)

        subject.event('category', 'action', label: 'label', property: 'property', value: 1.5)
      end
    end
  end

  context 'for callbacks' do
    describe 'on success' do
      it 'increase gitlab_successful_snowplow_events_total counter' do
        counter = double

        expect(counter).to receive(:increment).with({}, 2)
        expect(Gitlab::Metrics).to receive(:counter)
                                     .with(
                                       :gitlab_db_events_snowplow_successful_events_total,
                                       'Number of successful Snowplow events emissions').and_return(counter)

        subject.method(:increment_successful_events_emissions).call(2)
      end
    end

    describe 'on failure' do
      it 'increase gitlab_failed_snowplow_events_total counter and logs failures', :aggregate_failures do
        counter = double
        error_message = "Issue database_event_update failed to be reported to collector at localhost:9091"
        failures = [{ "e" => "se",
                      "se_ca" => "Issue",
                      "se_la" => "issues",
                      "se_ac" => "database_event_update" }]
        allow(Gitlab::Metrics).to receive(:counter)
                                    .with(
                                      :gitlab_db_events_snowplow_successful_events_total,
                                      'Number of successful Snowplow events emissions').and_call_original

        expect(Gitlab::AppLogger).to receive(:error).with(error_message)
        expect(counter).to receive(:increment).with({}, 1)
        expect(Gitlab::Metrics).to receive(:counter)
                                     .with(
                                       :gitlab_db_events_snowplow_failed_events_total,
                                       'Number of failed Snowplow events emissions').and_return(counter)

        subject.method(:failure_callback).call(2, failures)
      end
    end
  end
end
