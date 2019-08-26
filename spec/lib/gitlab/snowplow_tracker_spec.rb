# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::SnowplowTracker do
  let(:timestamp) { Time.utc(2017, 3, 22) }

  around do |example|
    Timecop.freeze(timestamp) { example.run }
  end

  subject { described_class.track_event('epics', 'action', property: 'what', value: 'doit') }

  context '.track_event' do
    context 'when Snowplow tracker is disabled' do
      it 'does not track the event' do
        expect(SnowplowTracker::Tracker).not_to receive(:new)

        subject
      end
    end

    context 'when Snowplow tracker is enabled' do
      before do
        stub_application_setting(snowplow_enabled: true)
        stub_application_setting(snowplow_site_id: 'awesome gitlab')
        stub_application_setting(snowplow_collector_hostname: 'url.com')
      end

      it 'tracks the event' do
        tracker = double

        expect(::SnowplowTracker::Tracker).to receive(:new)
          .with(
            an_instance_of(::SnowplowTracker::Emitter),
            an_instance_of(::SnowplowTracker::Subject),
            'cf', 'awesome gitlab'
          ).and_return(tracker)
        expect(tracker).to receive(:track_struct_event)
          .with('epics', 'action', nil, 'what', 'doit', nil, timestamp.to_i)

        subject
      end
    end
  end
end
