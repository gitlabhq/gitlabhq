# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::SyntheticLabelNotesBuilderService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let_it_be(:issue) { create(:issue, author: user) }

    let_it_be(:event1) { create(:resource_label_event, issue: issue) }
    let_it_be(:event2) { create(:resource_label_event, issue: issue) }
    let_it_be(:event3) { create(:resource_label_event, issue: issue) }

    it 'returns the expected synthetic notes' do
      notes = described_class.new(issue, user).execute

      expect(notes.size).to eq(3)
    end

    it_behaves_like 'filters by paginated notes', :resource_label_event
  end
end
