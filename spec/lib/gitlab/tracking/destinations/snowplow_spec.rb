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
        .with('gitfoo.com', { protocol: 'https' })
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
    end

    describe '#self_describing_event' do
      it 'sends event to tracker' do
        allow(tracker).to receive(:track_self_describing_event).and_call_original

        subject.self_describing_event('iglu:com.gitlab/foo/jsonschema/1-0-0', data: { foo: 'bar' })

        expect(tracker).to have_received(:track_self_describing_event) do |event, context, timestamp|
          expect(event.to_json[:schema]).to eq('iglu:com.gitlab/foo/jsonschema/1-0-0')
          expect(event.to_json[:data]).to eq(foo: 'bar')
          expect(context).to eq(nil)
          expect(timestamp).to eq((Time.now.to_f * 1000).to_i)
        end
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

    describe '#self_describing_event' do
      it 'does not send event to tracker' do
        expect_any_instance_of(SnowplowTracker::Tracker).not_to receive(:track_self_describing_event)

        subject.self_describing_event('iglu:com.gitlab/foo/jsonschema/1-0-0', data: { foo: 'bar' })
      end
    end
  end
end
