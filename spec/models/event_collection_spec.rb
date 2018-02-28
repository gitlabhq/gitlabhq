require 'spec_helper'

describe EventCollection do
  describe '#to_a' do
    let(:project) { create(:project_empty_repo) }
    let(:projects) { Project.where(id: project.id) }
    let(:user) { create(:user) }

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
      filter = EventFilter.new(EventFilter.issue)
      events = described_class.new(projects, filter: filter).to_a

      expect(events.length).to eq(1)
      expect(events[0].action).to eq(Event::CLOSED)
    end
  end
end
