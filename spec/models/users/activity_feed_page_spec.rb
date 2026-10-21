# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ActivityFeedPage, feature_category: :user_profile do
  let(:viewer) { instance_double(User) }
  let(:target_user) { instance_double(User, include_private_contributions?: false) }

  describe '#more?' do
    it 'is true when the probe row was returned' do
      expect(feed_page(Array.new(3) { build_event }, feed_limit: 2)).to be_more
    end

    it 'is false when the probe row was not returned' do
      expect(feed_page(Array.new(2) { build_event }, feed_limit: 2)).not_to be_more
    end

    it 'is false for a short page' do
      expect(feed_page([build_event], feed_limit: 2)).not_to be_more
    end

    it 'is false when the limit is zero' do
      expect(feed_page([build_event], feed_limit: 0, probe_limit: 1)).not_to be_more
    end

    context 'when there is no room for the probe row' do
      it 'is true for a full page' do
        expect(feed_page(Array.new(2) { build_event }, feed_limit: 2, probe_limit: 2)).to be_more
      end

      it 'is false for a short page' do
        expect(feed_page([build_event], feed_limit: 2, probe_limit: 2)).not_to be_more
      end
    end

    it 'is decided before visibility filtering' do
      page = feed_page(Array.new(3) { build_event(visible: false) }, feed_limit: 2)

      expect(page).to be_more
      expect(page.visible_events).to be_empty
    end
  end

  describe '#visible_events' do
    it 'drops the probe row' do
      events = Array.new(3) { build_event }

      expect(feed_page(events, feed_limit: 2).visible_events).to eq(events.first(2))
    end

    it 'keeps only events visible to the viewer' do
      visible = build_event
      hidden = build_event(visible: false)

      expect(feed_page([visible, hidden], feed_limit: 2).visible_events).to eq([visible])
    end

    context 'when the target user shows private contributions' do
      let(:target_user) { instance_double(User, include_private_contributions?: true) }

      it 'keeps hidden events and drops events whose target was deleted' do
        hidden = build_event(visible: false)
        deleted = build_event(target_deleted: true)

        expect(feed_page([hidden, deleted], feed_limit: 2).visible_events).to eq([hidden])
      end
    end
  end

  def build_event(visible: true, target_deleted: false)
    instance_double(Event, target_deleted?: target_deleted).tap do |event|
      allow(event).to receive(:visible_to_user?).with(viewer).and_return(visible)
    end
  end

  def feed_page(events, feed_limit:, probe_limit: feed_limit + 1)
    described_class.new(events, feed_limit: feed_limit, probe_limit: probe_limit,
      viewer: viewer, target_user: target_user)
  end
end
