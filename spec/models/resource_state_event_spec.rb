# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceStateEvent, feature_category: :team_planning, type: :model do
  subject { build(:resource_state_event, issue: issue) }

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:merge_request) { create(:merge_request) }
  let_it_be_with_reload(:project) { merge_request.target_project }
  let_it_be_with_reload(:issue) { create(:issue, project: project) }

  it_behaves_like 'a resource event'
  it_behaves_like 'a resource event that responds to imported'
  it_behaves_like 'a resource event for issues'
  it_behaves_like 'a resource event for merge requests'
  it_behaves_like 'a note for work item resource event'

  describe 'validations' do
    describe 'Issuable validation' do
      it 'is valid if an issue is set' do
        subject.attributes = { issue: issue, merge_request: nil }

        expect(subject).to be_valid
      end

      it 'is valid if a merge request is set' do
        subject.attributes = { issue: nil, merge_request: merge_request }

        expect(subject).to be_valid
      end

      it 'is invalid if both issue and merge request are set' do
        subject.attributes = { issue: issue, merge_request: merge_request }

        expect(subject).not_to be_valid
      end

      it 'is invalid if there is no issuable set' do
        subject.attributes = { issue: nil, merge_request: nil }

        expect(subject).not_to be_valid
      end
    end
  end

  context 'callbacks' do
    describe 'ensure_namespace_id' do
      context 'when state_event belongs to a project issue' do
        let(:state_event) { described_class.new(issue: issue) }

        it 'sets the namespace id from the issue namespace id' do
          expect(state_event.namespace_id).to be_nil

          state_event.valid?

          expect(state_event.namespace_id).to eq(issue.namespace.id)
        end
      end

      context 'when state_event belongs to a group issue' do
        let(:issue) { create(:issue, :group_level, namespace: group) }
        let(:state_event) { described_class.new(issue: issue) }

        it 'sets the namespace id from the issue namespace id' do
          expect(state_event.namespace_id).to be_nil

          state_event.valid?

          expect(state_event.namespace_id).to eq(issue.namespace.id)
        end
      end

      context 'when state_event belongs to a merge request' do
        let(:state_event) { described_class.new(merge_request: merge_request) }

        it 'sets the namespace id from the merge request project namespace id' do
          expect(state_event.namespace_id).to be_nil

          state_event.valid?

          expect(state_event.namespace_id).to eq(merge_request.project.project_namespace_id)
        end
      end
    end
  end

  describe '.merged_with_no_event_source', feature_category: :code_review_workflow do
    let!(:merged_event) { create(:resource_state_event, merge_request: merge_request, state: :merged) }

    before do
      create(:resource_state_event, merge_request: merge_request, state: :closed)
      create(:resource_state_event, merge_request: merge_request, state: :merged, source_merge_request: merge_request)
      create(:resource_state_event, merge_request: merge_request, state: :merged, source_commit: 'abcd1234')
    end

    subject { described_class.merged_with_no_event_source }

    it 'returns expected events' do
      expect(subject).to contain_exactly(merged_event)
    end
  end
end
