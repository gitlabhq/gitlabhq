# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::IssueActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let_it_be(:user1) { build(:user, id: 1) }
  let_it_be(:user2) { build(:user, id: 2) }
  let_it_be(:user3) { build(:user, id: 3) }
  let_it_be(:project) { create(:project) }
  let_it_be(:category) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CATEGORY }
  let_it_be(:event_action) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_ACTION }
  let_it_be(:event_label) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_LABEL }

  let(:original_params) { nil }
  let(:event_property) { action }
  let(:time) { Time.zone.now }

  context 'for Issue title edit actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_TITLE_CHANGED }

      def track_action(params)
        described_class.track_issue_title_changed_action(**params)
      end
    end
  end

  context 'for Issue description edit actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_DESCRIPTION_CHANGED }

      def track_action(params)
        described_class.track_issue_description_changed_action(**params)
      end
    end
  end

  context 'for Issue assignee edit actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_ASSIGNEE_CHANGED }

      def track_action(params)
        described_class.track_issue_assignee_changed_action(**params)
      end
    end
  end

  context 'for Issue make confidential actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_MADE_CONFIDENTIAL }

      def track_action(params)
        described_class.track_issue_made_confidential_action(**params)
      end
    end
  end

  context 'for Issue make visible actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_MADE_VISIBLE }

      def track_action(params)
        described_class.track_issue_made_visible_action(**params)
      end
    end
  end

  context 'for Issue created actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_CREATED }
      let(:original_params) { { namespace: project.project_namespace.reload } }

      def track_action(params)
        described_class.track_issue_created_action(**params)
      end
    end
  end

  context 'for Issue closed actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_CLOSED }

      def track_action(params)
        described_class.track_issue_closed_action(**params)
      end
    end
  end

  context 'for Issue reopened actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_REOPENED }

      def track_action(params)
        described_class.track_issue_reopened_action(**params)
      end
    end
  end

  context 'for Issue label changed actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_LABEL_CHANGED }

      def track_action(params)
        described_class.track_issue_label_changed_action(**params)
      end
    end
  end

  context 'for Issue label milestone actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_MILESTONE_CHANGED }

      def track_action(params)
        described_class.track_issue_milestone_changed_action(**params)
      end
    end
  end

  context 'for Issue cross-referenced actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_CROSS_REFERENCED }

      def track_action(params)
        described_class.track_issue_cross_referenced_action(**params)
      end
    end
  end

  context 'for Issue moved actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_MOVED }

      def track_action(params)
        described_class.track_issue_moved_action(**params)
      end
    end
  end

  context 'for Issue cloned actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let_it_be(:action) { described_class::ISSUE_CLONED }

      def track_action(params)
        described_class.track_issue_cloned_action(**params)
      end
    end
  end

  context 'for Issue relate actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_RELATED }

      def track_action(params)
        described_class.track_issue_related_action(**params)
      end
    end
  end

  context 'for Issue unrelate actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_UNRELATED }

      def track_action(params)
        described_class.track_issue_unrelated_action(**params)
      end
    end
  end

  context 'for Issue marked as duplicate actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_MARKED_AS_DUPLICATE }

      def track_action(params)
        described_class.track_issue_marked_as_duplicate_action(**params)
      end
    end
  end

  context 'for Issue locked actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_LOCKED }

      def track_action(params)
        described_class.track_issue_locked_action(**params)
      end
    end
  end

  context 'for Issue unlocked actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_UNLOCKED }

      def track_action(params)
        described_class.track_issue_unlocked_action(**params)
      end
    end
  end

  context 'for Issue designs added actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_DESIGNS_ADDED }

      def track_action(params)
        described_class.track_issue_designs_added_action(**params)
      end
    end
  end

  context 'for Issue designs modified actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_DESIGNS_MODIFIED }

      def track_action(params)
        described_class.track_issue_designs_modified_action(**params)
      end
    end
  end

  context 'for Issue designs removed actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_DESIGNS_REMOVED }

      def track_action(params)
        described_class.track_issue_designs_removed_action(**params)
      end
    end
  end

  context 'for Issue due date changed actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_DUE_DATE_CHANGED }

      def track_action(params)
        described_class.track_issue_due_date_changed_action(**params)
      end
    end
  end

  context 'for Issue time estimate changed actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_TIME_ESTIMATE_CHANGED }

      def track_action(params)
        described_class.track_issue_time_estimate_changed_action(**params)
      end
    end
  end

  context 'for Issue time spent changed actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_TIME_SPENT_CHANGED }

      def track_action(params)
        described_class.track_issue_time_spent_changed_action(**params)
      end
    end
  end

  context 'for Issue comment added actions', :snowplow do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_COMMENT_ADDED }

      def track_action(params)
        described_class.track_issue_comment_added_action(**params)
      end
    end
  end

  context 'for Issue comment edited actions', :snowplow do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_COMMENT_EDITED }

      def track_action(params)
        described_class.track_issue_comment_edited_action(**params)
      end
    end
  end

  context 'for Issue comment removed actions', :snowplow do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_COMMENT_REMOVED }

      def track_action(params)
        described_class.track_issue_comment_removed_action(**params)
      end
    end
  end

  context 'for Issue design comment removed actions' do
    it_behaves_like 'tracked issuable snowplow and service ping events with project' do
      let(:action) { described_class::ISSUE_DESIGN_COMMENT_REMOVED }

      def track_action(params)
        described_class.track_issue_design_comment_removed_action(**params)
      end
    end
  end

  it 'can return the count of actions per user deduplicated' do
    travel_to(Date.today.beginning_of_week) do # because events aggregated by week we need to emit events in the same week
      described_class.track_issue_title_changed_action(author: user1, project: project)
      described_class.track_issue_description_changed_action(author: user1, project: project)
      described_class.track_issue_assignee_changed_action(author: user1, project: project)
    end

    travel_to(Date.today.beginning_of_week + 2.days) do
      described_class.track_issue_title_changed_action(author: user2, project: project)
      described_class.track_issue_title_changed_action(author: user3, project: project)
      described_class.track_issue_description_changed_action(author: user3, project: project)
      described_class.track_issue_assignee_changed_action(author: user3, project: project)
    end

    events = [described_class::ISSUE_TITLE_CHANGED, described_class::ISSUE_DESCRIPTION_CHANGED, described_class::ISSUE_ASSIGNEE_CHANGED]
    week_count = Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: events, start_date: time.beginning_of_week,
      end_date: time + 1.week)

    expect(week_count).to eq(3)
  end
end
