# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::TrackUniqueActions, :clean_gitlab_redis_shared_state do
  let(:time) { Time.zone.now }
  let(:action) { 'example_action' }

  def track_action(params)
    described_class.track_action(params)
  end

  def count_unique(params)
    described_class.count_unique(params)
  end

  context 'tracking an event' do
    context 'when tracking successfully' do
      it 'tracks and counts the events as expected' do
        stub_application_setting(usage_ping_enabled: true)

        aggregate_failures do
          expect(track_action(action: action, author_id: 1)).to be_truthy
          expect(track_action(action: action, author_id: 1)).to be_truthy
          expect(track_action(action: action, author_id: 2)).to be_truthy
          expect(track_action(action: action, author_id: 3, time: time - 3.days)).to be_truthy

          expect(count_unique(action: action, date_from: time, date_to: Date.today)).to eq(2)
          expect(count_unique(action: action, date_from: time - 5.days, date_to: Date.tomorrow)).to eq(3)
        end
      end
    end

    context 'when tracking unsuccessfully' do
      it 'does not track the event' do
        stub_application_setting(usage_ping_enabled: false)

        expect(track_action(action: action, author_id: 2)).to be_nil
        expect(count_unique(action: action, date_from: time, date_to: Date.today)).to eq(0)
      end
    end
  end
end
