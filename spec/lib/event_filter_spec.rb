require 'spec_helper'

describe EventFilter, lib: true do
  describe '#apply_filter' do
    let(:source_user) { create(:user) }
    let!(:public_project) { create(:project, :public) }

    let!(:push_event) { create(:event, action: Event::PUSHED, project: public_project, target: public_project, author: source_user) }
    let!(:merged_event) { create(:event, action: Event::MERGED, project: public_project, target: public_project, author: source_user) }
    let!(:comments_event) { create(:event, action: Event::COMMENTED, project: public_project, target: public_project, author: source_user) }
    let!(:joined_event) { create(:event, action: Event::JOINED, project: public_project, target: public_project, author: source_user) }
    let!(:left_event) { create(:event, action: Event::LEFT, project: public_project, target: public_project, author: source_user) }

    it 'applies push filter' do
      events = EventFilter.new(EventFilter.push).apply_filter(Event.all)
      expect(events).to contain_exactly(push_event)
    end

    it 'applies merged filter' do
      events = EventFilter.new(EventFilter.merged).apply_filter(Event.all)
      expect(events).to contain_exactly(merged_event)
    end

    it 'applies comments filter' do
      events = EventFilter.new(EventFilter.comments).apply_filter(Event.all)
      expect(events).to contain_exactly(comments_event)
    end

    it 'applies team filter' do
      events = EventFilter.new(EventFilter.team).apply_filter(Event.all)
      expect(events).to contain_exactly(joined_event, left_event)
    end

    it 'applies all filter' do
      events = EventFilter.new(EventFilter.all).apply_filter(Event.all)
      expect(events).to contain_exactly(push_event, merged_event, comments_event, joined_event, left_event)
    end

    it 'applies no filter' do
      events = EventFilter.new(nil).apply_filter(Event.all)
      expect(events).to contain_exactly(push_event, merged_event, comments_event, joined_event, left_event)
    end

    it 'applies unknown filter' do
      events = EventFilter.new('').apply_filter(Event.all)
      expect(events).to contain_exactly(push_event, merged_event, comments_event, joined_event, left_event)
    end
  end
end
