# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Tracker do
  it { expect(described_class::URL).to eq('http://localhost/-/sp.js') }
  it { expect(described_class::COLLECTOR_URL).to eq('localhost/-/collector') }

  describe '.event' do
    after do
      described_class.clear_memoization(:snowplow)
    end

    context 'when usage ping is enabled' do
      let(:tracker) { double }
      let(:project_id) { 1 }

      before do
        stub_application_setting(usage_ping_enabled: true, self_monitoring_project_id: project_id)
      end

      it 'sends an event to Product Analytics snowplow collector' do
        expect(SnowplowTracker::AsyncEmitter)
          .to receive(:new)
          .with(described_class::COLLECTOR_URL, { protocol: 'http' })
          .and_return('_emitter_')

        expect(SnowplowTracker::Tracker)
          .to receive(:new)
          .with('_emitter_', an_instance_of(SnowplowTracker::Subject), 'gl', project_id.to_s)
          .and_return(tracker)

        freeze_time do
          expect(tracker)
            .to receive(:track_struct_event)
            .with('category', 'action', '_label_', '_property_', '_value_', nil, (Time.current.to_f * 1000).to_i)

          described_class.event('category', 'action', label: '_label_', property: '_property_',
                                value: '_value_', context: nil)
        end
      end
    end

    context 'when usage ping is disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)
      end

      it 'does not send an event' do
        expect(SnowplowTracker::Tracker).not_to receive(:new)

        described_class.event('category', 'action', label: '_label_', property: '_property_',
                              value: '_value_', context: nil)
      end
    end
  end
end
