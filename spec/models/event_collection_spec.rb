# frozen_string_literal: true

require 'spec_helper'

describe EventCollection do
  describe '#to_a' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project_empty_repo, group: group) }
    let_it_be(:projects) { Project.where(id: project.id) }
    let_it_be(:user) { create(:user) }

    context 'with project events' do
      before do
        20.times do
          event = create(:push_event, project: project, author: user)

          create(:push_event_payload, event: event)
        end

        create(:closed_issue_event, project: project, author: user)
      end

      it 'returns an Array of events' do
        events = described_class.new(projects).to_a

        expect(events).to be_an_instance_of(Array)
      end

      it 'applies a limit to the number of events' do
        events = described_class.new(projects).to_a

        expect(events.length).to eq(20)
      end

      it 'can paginate through events' do
        events = described_class.new(projects, offset: 20).to_a

        expect(events.length).to eq(1)
      end

      it 'returns an empty Array when crossing the maximum page number' do
        events = described_class.new(projects, limit: 1, offset: 15).to_a

        expect(events).to be_empty
      end

      it 'allows filtering of events using an EventFilter' do
        filter = EventFilter.new(EventFilter::ISSUE)
        events = described_class.new(projects, filter: filter).to_a

        expect(events.length).to eq(1)
        expect(events[0].action).to eq(Event::CLOSED)
      end
    end

    context 'with group events' do
      let(:groups) { group.self_and_descendants.public_or_visible_to_user(user) }
      let(:subject) { described_class.new(projects, groups: groups).to_a }

      it 'includes also group events' do
        subgroup = create(:group, parent: group)
        event1 = create(:event, project: project, author: user)
        event2 = create(:event, project: nil, group: group, author: user)
        event3 = create(:event, project: nil, group: subgroup, author: user)

        expect(subject).to eq([event3, event2, event1])
      end

      it 'does not include events from inaccessible groups' do
        subgroup = create(:group, :private, parent: group)
        event1 = create(:event, project: nil, group: group, author: user)
        create(:event, project: nil, group: subgroup, author: user)

        expect(subject).to eq([event1])
      end
    end
  end
end
