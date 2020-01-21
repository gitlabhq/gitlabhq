# frozen_string_literal: true

require 'spec_helper'

describe ResourceEvents::SyntheticLabelNotesBuilderService do
  describe '#execute' do
    let!(:user) { create(:user) }

    let!(:issue) { create(:issue, author: user) }

    let!(:event1) { create(:resource_label_event, issue: issue) }
    let!(:event2) { create(:resource_label_event, issue: issue) }
    let!(:event3) { create(:resource_label_event, issue: issue) }

    it 'returns the expected synthetic notes' do
      notes = ResourceEvents::SyntheticLabelNotesBuilderService.new(issue, user).execute

      expect(notes.size).to eq(3)
    end
  end
end
