# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::SyntheticMilestoneNotesBuilderService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue, author: user) }
    let_it_be(:milestone) { create(:milestone, project: issue.project) }

    let_it_be(:events) do
      [
        create(:resource_milestone_event, issue: issue, milestone: milestone, action: :add, created_at: '2020-01-01 04:00'),
        create(:resource_milestone_event, issue: issue, milestone: milestone, action: :remove, created_at: '2020-01-02 08:00')
      ]
    end

    it 'builds milestone notes for resource milestone events' do
      notes = described_class.new(issue, user).execute

      expect(notes.map(&:created_at)).to eq(events.map(&:created_at))
      expect(notes.map(&:note)).to eq([
        "changed milestone to %#{milestone.iid}",
        'removed milestone'
      ])
    end
  end
end
