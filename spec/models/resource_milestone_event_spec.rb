# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceMilestoneEvent, feature_category: :team_planning, type: :model do
  it_behaves_like 'a resource event'
  it_behaves_like 'a resource event for issues'
  it_behaves_like 'a resource event for merge requests'
  it_behaves_like 'a note for work item resource event'
  it_behaves_like 'a resource event that responds to imported'

  it_behaves_like 'having unique enum values'
  it_behaves_like 'timebox resource event validations'
  it_behaves_like 'timebox resource event states'
  it_behaves_like 'timebox resource event actions'
  it_behaves_like 'timebox resource tracks issue metrics', :milestone

  describe 'associations' do
    it { is_expected.to belong_to(:milestone) }
  end

  describe '#milestone_title' do
    let(:milestone) { create(:milestone, title: 'v2.3') }
    let(:event) { create(:resource_milestone_event, milestone: milestone) }

    it 'returns the expected title' do
      expect(event.milestone_title).to eq('v2.3')
    end

    context 'when milestone is nil' do
      let(:event) { create(:resource_milestone_event, milestone: nil) }

      it 'returns nil' do
        expect(event.milestone_title).to be_nil
      end
    end
  end

  describe '#milestone_parent' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group) }

    let(:milestone) { create(:milestone, project: project) }
    let(:event) { create(:resource_milestone_event, milestone: milestone) }

    context 'when milestone parent is project' do
      it 'returns the expected parent' do
        expect(event.milestone_parent).to eq(project)
      end
    end

    context 'when milestone parent is group' do
      let(:milestone) { create(:milestone, group: group) }

      it 'returns the expected parent' do
        expect(event.milestone_parent).to eq(group)
      end
    end

    context 'when milestone is nil' do
      let(:event) { create(:resource_milestone_event, milestone: nil) }

      it 'returns nil' do
        expect(event.milestone_parent).to be_nil
      end
    end
  end
end
