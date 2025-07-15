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
    describe '#issue_usage_metrics' do
      describe 'when an issue is closed' do
        subject(:close_issue) do
          create(
            described_class.name.underscore.to_sym,
            issue: issue,
            state: described_class.states[:closed]
          )
        end

        it 'tracks closed issues' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_closed_action)

          close_issue
        end

        it_behaves_like 'internal event tracking' do
          subject(:service_action) { close_issue }

          let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CLOSED }
          let(:project) { issue.project }
          let(:user) { issue.author }

          let(:issue) do
            # The g_project_management_issue_created event is triggered by creating the issue.
            # So we'll trigger the irrelevant event outside of the metric time ranges
            travel_to(2.months.ago) { create(:issue) }
          end
        end
      end

      describe 'when an issue is reopened' do
        subject(:reopen_issue) do
          create(
            described_class.name.underscore.to_sym,
            issue: issue,
            state: described_class.states[:reopened]
          )
        end

        it 'tracks reopened issues' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_reopened_action)

          reopen_issue
        end

        it_behaves_like 'internal event tracking' do
          subject(:service_action) { reopen_issue }

          let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_REOPENED }
          let(:project) { issue.project }
          let(:user) { issue.author }

          let(:issue) do
            # The g_project_management_issue_created event is triggered by creating the issue.
            # So we'll trigger the irrelevant event outside of the metric time ranges
            travel_to(2.months.ago) { create(:issue) }
          end
        end
      end

      it 'does not track merge requests' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_closed_action)

        create(described_class.name.underscore.to_sym, merge_request: merge_request, state: described_class.states[:closed])
      end
    end

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

          expect(state_event.namespace_id).to eq(merge_request.source_project.project_namespace_id)
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
