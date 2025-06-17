# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceMilestoneEvent, feature_category: :team_planning, type: :model do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

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

    it { is_expected.to belong_to(:namespace) }

    it { is_expected.to belong_to(:issue) }

    it { is_expected.to belong_to(:merge_request) }
  end

  describe 'validations' do
    describe 'issue presence' do
      it { is_expected.to validate_presence_of(:issue) }

      context 'when merge_request is present' do
        subject { described_class.new(merge_request: build_stubbed(:merge_request)) }

        it { is_expected.not_to validate_presence_of(:issue) }
      end
    end

    describe 'merge_request presence' do
      it { is_expected.to validate_presence_of(:merge_request) }

      context 'when issue is present' do
        subject { described_class.new(issue: build_stubbed(:issue)) }

        it { is_expected.not_to validate_presence_of(:merge_request) }
      end
    end

    describe 'issue and merge_request mutually exclusive' do
      context 'when merge_request is present' do
        it 'validates that merge_request and issue are mutually exclusive' do
          expect(
            described_class.new(merge_request: create(:merge_request, source_project: project))
          ).to validate_absence_of(:issue).with_message(_("can't be specified if a merge request was already provided"))
        end
      end

      context 'when merge_request is not present' do
        it { is_expected.not_to validate_absence_of(:issue) }
      end
    end
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

  describe 'ensure_namespace_id' do
    context 'when event belongs to an issue' do
      let(:issue) { create(:issue, project: project) }
      let(:event) { described_class.new(issue: issue) }

      it 'sets the namespace id from the issue namespace id' do
        event.valid?

        expect(event.namespace_id).to eq(issue.namespace.id)
      end
    end

    context 'when event belongs to a merge request' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:event) { described_class.new(merge_request: merge_request) }

      it 'sets the namespace id from the merge request project namespace id' do
        event.valid?

        expect(event.namespace_id).to eq(merge_request.source_project.project_namespace_id)
      end
    end
  end
end
