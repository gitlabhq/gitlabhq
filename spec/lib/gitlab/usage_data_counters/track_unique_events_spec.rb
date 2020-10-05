# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::TrackUniqueEvents, :clean_gitlab_redis_shared_state do
  subject(:track_unique_events) { described_class }

  let(:time) { Time.zone.now }

  def track_event(params)
    track_unique_events.track_event(**params)
  end

  def count_unique(params)
    track_unique_events.count_unique_events(**params)
  end

  context 'tracking an event' do
    context 'when tracking successfully' do
      context 'when the application setting is enabled' do
        context 'when the target and the action is valid' do
          before do
            stub_application_setting(usage_ping_enabled: true)
          end

          it 'tracks and counts the events as expected' do
            project = Event::TARGET_TYPES[:project]
            design = Event::TARGET_TYPES[:design]
            wiki = Event::TARGET_TYPES[:wiki]

            expect(track_event(event_action: :pushed, event_target: project, author_id: 1)).to be_truthy
            expect(track_event(event_action: :pushed, event_target: project, author_id: 1)).to be_truthy
            expect(track_event(event_action: :pushed, event_target: project, author_id: 2)).to be_truthy
            expect(track_event(event_action: :pushed, event_target: project, author_id: 3)).to be_truthy
            expect(track_event(event_action: :pushed, event_target: project, author_id: 4, time: time - 3.days)).to be_truthy

            expect(track_event(event_action: :destroyed, event_target: design, author_id: 3)).to be_truthy
            expect(track_event(event_action: :created, event_target: design, author_id: 4)).to be_truthy
            expect(track_event(event_action: :updated, event_target: design, author_id: 5)).to be_truthy

            expect(track_event(event_action: :destroyed, event_target: wiki, author_id: 5)).to be_truthy
            expect(track_event(event_action: :created, event_target: wiki, author_id: 3)).to be_truthy
            expect(track_event(event_action: :updated, event_target: wiki, author_id: 4)).to be_truthy

            expect(count_unique(event_action: described_class::PUSH_ACTION, date_from: time, date_to: Date.today)).to eq(3)
            expect(count_unique(event_action: described_class::PUSH_ACTION, date_from: time - 5.days, date_to: Date.tomorrow)).to eq(4)
            expect(count_unique(event_action: described_class::DESIGN_ACTION, date_from: time - 5.days, date_to: Date.today)).to eq(3)
            expect(count_unique(event_action: described_class::WIKI_ACTION, date_from: time - 5.days, date_to: Date.today)).to eq(3)
            expect(count_unique(event_action: described_class::PUSH_ACTION, date_from: time - 5.days, date_to: time - 2.days)).to eq(1)
          end
        end
      end
    end

    context 'when tracking unsuccessfully' do
      using RSpec::Parameterized::TableSyntax

      where(:target, :action) do
        Project         | :invalid_action
        :invalid_target | :pushed
        Project         | :created
      end

      with_them do
        it 'returns the expected values' do
          expect(track_event(event_action: action, event_target: target, author_id: 2)).to be_nil
          expect(count_unique(event_action: described_class::PUSH_ACTION, date_from: time, date_to: Date.today)).to eq(0)
        end
      end
    end
  end
end
