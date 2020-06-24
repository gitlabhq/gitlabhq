# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::SyntheticMilestoneNotesBuilderService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue, author: user) }

    before do
      create_list(:resource_milestone_event, 3, issue: issue)

      stub_feature_flags(track_resource_milestone_change_events: false)
    end

    context 'when resource milestone events are disabled' do
      # https://gitlab.com/gitlab-org/gitlab/-/issues/212985
      it 'still builds notes for existing resource milestone events' do
        notes = described_class.new(issue, user).execute

        expect(notes.size).to eq(3)
      end
    end
  end
end
