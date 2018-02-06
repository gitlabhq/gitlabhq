require 'spec_helper'

describe EventFilter do
  describe '#apply_filter' do
    let(:source_user) { create(:user) }
    let!(:public_project) { create(:project, :public) }

    let!(:push_event)     { create(:push_event,        project: public_project, author: source_user) }
    let!(:merged_event)   { create(:event, :merged,    project: public_project, target: public_project, author: source_user) }
    let!(:created_event)  { create(:event, :created,   project: public_project, target: public_project, author: source_user) }
    let!(:updated_event)  { create(:event, :updated,   project: public_project, target: public_project, author: source_user) }
    let!(:closed_event)   { create(:event, :closed,    project: public_project, target: public_project, author: source_user) }
    let!(:reopened_event) { create(:event, :reopened,  project: public_project, target: public_project, author: source_user) }
    let!(:comments_event) { create(:event, :commented, project: public_project, target: public_project, author: source_user) }
    let!(:joined_event)   { create(:event, :joined,    project: public_project, target: public_project, author: source_user) }
    let!(:left_event)     { create(:event, :left,      project: public_project, target: public_project, author: source_user) }

    it 'applies push filter' do
      events = described_class.new(described_class.push).apply_filter(Event.all)
      expect(events).to contain_exactly(push_event)
    end

    it 'applies merged filter' do
      events = described_class.new(described_class.merged).apply_filter(Event.all)
      expect(events).to contain_exactly(merged_event)
    end

    it 'applies issue filter' do
      events = described_class.new(described_class.issue).apply_filter(Event.all)
      expect(events).to contain_exactly(created_event, updated_event, closed_event, reopened_event)
    end

    it 'applies comments filter' do
      events = described_class.new(described_class.comments).apply_filter(Event.all)
      expect(events).to contain_exactly(comments_event)
    end

    it 'applies team filter' do
      events = described_class.new(described_class.team).apply_filter(Event.all)
      expect(events).to contain_exactly(joined_event, left_event)
    end

    it 'applies all filter' do
      events = described_class.new(described_class.all).apply_filter(Event.all)
      expect(events).to contain_exactly(push_event, merged_event, created_event, updated_event, closed_event, reopened_event, comments_event, joined_event, left_event)
    end

    it 'applies no filter' do
      events = described_class.new(nil).apply_filter(Event.all)
      expect(events).to contain_exactly(push_event, merged_event, created_event, updated_event, closed_event, reopened_event, comments_event, joined_event, left_event)
    end

    it 'applies unknown filter' do
      events = described_class.new('').apply_filter(Event.all)
      expect(events).to contain_exactly(push_event, merged_event, created_event, updated_event, closed_event, reopened_event, comments_event, joined_event, left_event)
    end
  end
end
