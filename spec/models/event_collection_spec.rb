# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventCollection do
  include DesignManagementTestHelpers

  describe '#to_a' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project_empty_repo, group: group) }
    let_it_be(:projects) { Project.where(id: project.id) }
    let_it_be(:user) { create(:user) }
    let_it_be(:merge_request) { create(:merge_request) }

    before do
      enable_design_management
    end

    context 'with project events' do
      let_it_be(:push_event_payloads) do
        Array.new(9) do
          create(:push_event_payload,
                 event: create(:push_event, project: project, author: user))
        end
      end

      let_it_be(:merge_request_events) { create_list(:event, 10, :commented, project: project, target: merge_request) }
      let_it_be(:closed_issue_event) { create(:closed_issue_event, project: project, author: user) }
      let_it_be(:wiki_page_event) { create(:wiki_page_event, project: project) }
      let_it_be(:design_event) { create(:design_event, project: project) }

      let(:push_events) { push_event_payloads.map(&:event) }

      it 'returns an Array of events', :aggregate_failures do
        most_recent_20_events = [
          wiki_page_event,
          design_event,
          closed_issue_event,
          *push_events,
          *merge_request_events
        ].sort_by(&:id).reverse.take(20)
        events = described_class.new(projects).to_a

        expect(events).to be_an_instance_of(Array)
        expect(events).to match_array(most_recent_20_events)
      end

      it 'includes the wiki page events when using to_a' do
        events = described_class.new(projects).to_a

        expect(events).to include(wiki_page_event)
      end

      it 'includes the design events' do
        collection = described_class.new(projects)

        expect(collection.to_a).to include(design_event)
        expect(collection.all_project_events).to include(design_event)
      end

      it 'includes the wiki page events when using all_project_events' do
        events = described_class.new(projects).all_project_events

        expect(events).to include(wiki_page_event)
      end

      it 'applies a limit to the number of events' do
        events = described_class.new(projects).to_a

        expect(events.length).to eq(20)
      end

      it 'can paginate through events' do
        events = described_class.new(projects, offset: 20).to_a

        expect(events.length).to eq(2)
      end

      it 'returns an empty Array when crossing the maximum page number' do
        events = described_class.new(projects, limit: 1, offset: 15).to_a

        expect(events).to be_empty
      end

      it 'allows filtering of events using an EventFilter, returning single item' do
        filter = EventFilter.new(EventFilter::ISSUE)
        events = described_class.new(projects, filter: filter).to_a

        expect(events).to contain_exactly(closed_issue_event)
      end

      it 'allows filtering of events using an EventFilter, returning several items' do
        filter = EventFilter.new(EventFilter::COMMENTS)
        events = described_class.new(projects, filter: filter).to_a

        expect(events).to match_array(merge_request_events)
      end

      it 'allows filtering of events using an EventFilter, returning pushes' do
        filter = EventFilter.new(EventFilter::PUSH)
        events = described_class.new(projects, filter: filter).to_a

        expect(events).to match_array(push_events)
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
