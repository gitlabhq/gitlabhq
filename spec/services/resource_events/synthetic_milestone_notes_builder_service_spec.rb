# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::SyntheticMilestoneNotesBuilderService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue, author: user) }
    let_it_be(:milestone) { create(:milestone, project: issue.project) }

    let_it_be(:events) do
      [
        create(:resource_milestone_event, issue: issue, milestone: milestone, action: :add, created_at: '2020-01-01 04:00'),
        create(:resource_milestone_event, issue: issue, milestone: milestone, action: :remove, created_at: '2020-01-02 08:00'),
        create(:resource_milestone_event, issue: issue, milestone: nil, action: :remove, created_at: '2020-01-02 08:00')
      ]
    end

    it 'builds milestone notes for resource milestone events' do
      notes = described_class.new(issue, user).execute

      expect(notes.map(&:created_at)).to eq(events.map(&:created_at))
      expect(notes.map(&:note)).to eq(
        [
          "changed milestone to #{milestone.to_reference(format: :iid, full: true, absolute_path: true)}",
          "removed milestone #{milestone.to_reference(format: :iid, full: true, absolute_path: true)}",
          "removed milestone "
        ])
    end

    it_behaves_like 'filters by paginated notes', :resource_milestone_event
  end
end
