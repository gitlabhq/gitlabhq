# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::ProductAnalytics do
  let(:emitter) { SnowplowTracker::Emitter.new('localhost', buffer_size: 1) }
  let(:tracker) { SnowplowTracker::Tracker.new(emitter, SnowplowTracker::Subject.new, 'namespace', 'app_id') }

  describe '#event' do
    shared_examples 'does not send an event' do
      it 'does not send an event' do
        expect_any_instance_of(SnowplowTracker::Tracker).not_to receive(:track_struct_event)

        subject.event(allowed_category, allowed_action)
      end
    end

    let(:allowed_category) { 'epics' }
    let(:allowed_action) { 'promote' }
    let(:self_monitoring_project) { create(:project) }

    before do
      stub_feature_flags(product_analytics_tracking: true)
      stub_application_setting(self_monitoring_project_id: self_monitoring_project.id)
      stub_application_setting(usage_ping_enabled: true)
    end

    context 'with allowed event' do
      it 'sends an event to Product Analytics snowplow collector' do
        expect(SnowplowTracker::AsyncEmitter)
          .to receive(:new)
          .with(ProductAnalytics::Tracker::COLLECTOR_URL, protocol: Gitlab.config.gitlab.protocol)
          .and_return(emitter)

        expect(SnowplowTracker::Tracker)
          .to receive(:new)
          .with(emitter, an_instance_of(SnowplowTracker::Subject), Gitlab::Tracking::SNOWPLOW_NAMESPACE, self_monitoring_project.id.to_s)
          .and_return(tracker)

        freeze_time do
          expect(tracker)
            .to receive(:track_struct_event)
            .with(allowed_category, allowed_action, 'label', 'property', 1.5, nil, (Time.now.to_f * 1000).to_i)

          subject.event(allowed_category, allowed_action, label: 'label', property: 'property', value: 1.5)
        end
      end
    end

    context 'with non-allowed event' do
      it 'does not send an event' do
        expect_any_instance_of(SnowplowTracker::Tracker).not_to receive(:track_struct_event)

        subject.event('category', 'action')
        subject.event(allowed_category, 'action')
        subject.event('category', allowed_action)
      end
    end

    context 'when self-monitoring project does not exist' do
      before do
        stub_application_setting(self_monitoring_project_id: nil)
      end

      include_examples 'does not send an event'
    end

    context 'when product_analytics_tracking FF is disabled' do
      before do
        stub_feature_flags(product_analytics_tracking: false)
      end

      include_examples 'does not send an event'
    end

    context 'when usage ping is disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)
      end

      include_examples 'does not send an event'
    end
  end
end
