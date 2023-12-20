# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:merge_request) { build(:merge_request, id: 1) }
  let(:user) { build(:user, id: 1) }
  let(:note) { build(:note, author: user) }

  shared_examples_for 'a tracked merge request unique event' do
    specify do
      expect { 3.times { subject } }
        .to change {
          Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
            event_names: action,
            start_date: 2.weeks.ago,
            end_date: 2.weeks.from_now
          )
        }
        .by(1)
    end
  end

  shared_examples_for 'not tracked merge request unique event' do
    specify do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      subject
    end
  end

  describe '.track_mr_diffs_action' do
    subject { described_class.track_mr_diffs_action(merge_request: merge_request) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_DIFFS_ACTION }
    end
  end

  describe '.track_mr_diffs_single_file_action' do
    subject { described_class.track_mr_diffs_single_file_action(merge_request: merge_request, user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_DIFFS_SINGLE_FILE_ACTION }
    end

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_DIFFS_USER_SINGLE_FILE_ACTION }
    end
  end

  describe '.track_create_mr_action' do
    subject { described_class.track_create_mr_action(user: user, merge_request: merge_request) }

    let(:merge_request) { create(:merge_request) }
    let(:target_project) { merge_request.target_project }

    it_behaves_like 'internal event tracking' do
      let(:event) { described_class::MR_USER_CREATE_ACTION }
      let(:project) { target_project }
      let(:namespace) { project.namespace }
    end
  end

  describe '.track_close_mr_action' do
    subject { described_class.track_close_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_CLOSE_ACTION }
    end
  end

  describe '.track_merge_mr_action' do
    subject { described_class.track_merge_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_MERGE_ACTION }
    end
  end

  describe '.track_reopen_mr_action' do
    subject { described_class.track_reopen_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_REOPEN_ACTION }
    end
  end

  describe '.track_approve_mr_action' do
    include ProjectForksHelper

    let(:merge_request) { create(:merge_request, target_project: target_project, source_project: source_project) }
    let(:source_project) { fork_project(target_project) }
    let(:target_project) { create(:project) }

    subject { described_class.track_approve_mr_action(user: user, merge_request: merge_request) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_APPROVE_ACTION }
    end

    it_behaves_like 'Snowplow event tracking with RedisHLL context' do
      let(:action) { :approve }
      let(:category) { described_class.name }
      let(:project) { target_project }
      let(:namespace) { project.namespace.reload }
      let(:user) { project.creator }
      let(:label) { 'redis_hll_counters.code_review.i_code_review_user_approve_mr_monthly' }
      let(:property) { described_class::MR_APPROVE_ACTION }
    end
  end

  describe '.track_unapprove_mr_action' do
    subject { described_class.track_unapprove_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_UNAPPROVE_ACTION }
    end
  end

  describe '.track_resolve_thread_action' do
    subject { described_class.track_resolve_thread_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_RESOLVE_THREAD_ACTION }
    end
  end

  describe '.track_unresolve_thread_action' do
    subject { described_class.track_unresolve_thread_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_UNRESOLVE_THREAD_ACTION }
    end
  end

  describe '.track_title_edit_action' do
    subject { described_class.track_title_edit_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_EDIT_MR_TITLE_ACTION }
    end
  end

  describe '.track_description_edit_action' do
    subject { described_class.track_description_edit_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_EDIT_MR_DESC_ACTION }
    end
  end

  describe '.track_create_comment_action' do
    subject { described_class.track_create_comment_action(note: note) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_CREATE_COMMENT_ACTION }
    end

    context 'when the note is multiline diff note' do
      let(:note) { build(:diff_note_on_merge_request, author: user) }

      before do
        allow(note).to receive(:multiline?).and_return(true)
      end

      it_behaves_like 'a tracked merge request unique event' do
        let(:action) { described_class::MR_CREATE_MULTILINE_COMMENT_ACTION }
      end
    end
  end

  describe '.track_edit_comment_action' do
    subject { described_class.track_edit_comment_action(note: note) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_EDIT_COMMENT_ACTION }
    end

    context 'when the note is multiline diff note' do
      let(:note) { build(:diff_note_on_merge_request, author: user) }

      before do
        allow(note).to receive(:multiline?).and_return(true)
      end

      it_behaves_like 'a tracked merge request unique event' do
        let(:action) { described_class::MR_EDIT_MULTILINE_COMMENT_ACTION }
      end
    end
  end

  describe '.track_remove_comment_action' do
    subject { described_class.track_remove_comment_action(note: note) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_REMOVE_COMMENT_ACTION }
    end

    context 'when the note is multiline diff note' do
      let(:note) { build(:diff_note_on_merge_request, author: user) }

      before do
        allow(note).to receive(:multiline?).and_return(true)
      end

      it_behaves_like 'a tracked merge request unique event' do
        let(:action) { described_class::MR_REMOVE_MULTILINE_COMMENT_ACTION }
      end
    end
  end

  describe '.track_create_review_note_action' do
    subject { described_class.track_create_review_note_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_CREATE_REVIEW_NOTE_ACTION }
    end
  end

  describe '.track_publish_review_action' do
    subject { described_class.track_publish_review_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_PUBLISH_REVIEW_ACTION }
    end
  end

  describe '.track_add_suggestion_action' do
    subject { described_class.track_add_suggestion_action(note: note) }

    before do
      note.suggestions << build(:suggestion, id: 1, note: note)
    end

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_USER_ADD_SUGGESTION_ACTION }
    end

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_TOTAL_ADD_SUGGESTION_ACTION }
    end
  end

  describe '.track_apply_suggestion_action' do
    subject { described_class.track_apply_suggestion_action(user: user, suggestions: suggestions) }

    let(:suggestions) { [build(:suggestion, id: 1, note: note)] }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_USER_APPLY_SUGGESTION_ACTION }
    end

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_TOTAL_APPLY_SUGGESTION_ACTION }
    end
  end

  describe '.track_users_assigned_to_mr' do
    subject { described_class.track_users_assigned_to_mr(users: [user]) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_ASSIGNED_USERS_ACTION }
    end
  end

  describe '.track_marked_as_draft_action' do
    subject { described_class.track_marked_as_draft_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_MARKED_AS_DRAFT_ACTION }
    end
  end

  describe '.track_unmarked_as_draft_action' do
    subject { described_class.track_unmarked_as_draft_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_UNMARKED_AS_DRAFT_ACTION }
    end
  end

  describe '.track_task_item_status_changed' do
    subject { described_class.track_task_item_status_changed(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_TASK_ITEM_STATUS_CHANGED_ACTION }
    end
  end

  describe '.track_users_review_requested' do
    subject { described_class.track_users_review_requested(users: [user]) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_REVIEW_REQUESTED_USERS_ACTION }
    end
  end

  describe '.track_approval_rule_added_action' do
    subject { described_class.track_approval_rule_added_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_APPROVAL_RULE_ADDED_USERS_ACTION }
    end
  end

  describe '.track_approval_rule_edited_action' do
    subject { described_class.track_approval_rule_edited_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_APPROVAL_RULE_EDITED_USERS_ACTION }
    end
  end

  describe '.track_approval_rule_deleted_action' do
    subject { described_class.track_approval_rule_deleted_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_APPROVAL_RULE_DELETED_USERS_ACTION }
    end
  end

  describe '.track_mr_create_from_issue' do
    subject { described_class.track_mr_create_from_issue(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_CREATE_FROM_ISSUE_ACTION }
    end
  end

  describe '.track_discussion_locked_action' do
    subject { described_class.track_discussion_locked_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_DISCUSSION_LOCKED_ACTION }
    end
  end

  describe '.track_discussion_unlocked_action' do
    subject { described_class.track_discussion_unlocked_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_DISCUSSION_UNLOCKED_ACTION }
    end
  end

  describe '.track_time_estimate_changed_action' do
    subject { described_class.track_time_estimate_changed_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_TIME_ESTIMATE_CHANGED_ACTION }
    end
  end

  describe '.track_time_spent_changed_action' do
    subject { described_class.track_time_spent_changed_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_TIME_SPENT_CHANGED_ACTION }
    end
  end

  describe '.track_assignees_changed_action' do
    subject { described_class.track_assignees_changed_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_ASSIGNEES_CHANGED_ACTION }
    end
  end

  describe '.track_reviewers_changed_action' do
    subject { described_class.track_reviewers_changed_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_REVIEWERS_CHANGED_ACTION }
    end
  end

  describe '.track_mr_including_ci_config' do
    subject { described_class.track_mr_including_ci_config(user: user, merge_request: merge_request) }

    context 'when merge request includes a ci config change' do
      before do
        allow(merge_request).to receive(:diff_stats).and_return([double(path: 'abc.txt'), double(path: '.gitlab-ci.yml')])
      end

      it_behaves_like 'a tracked merge request unique event' do
        let(:action) { described_class::MR_INCLUDING_CI_CONFIG_ACTION }
      end
    end

    context 'when merge request does not include any ci config change' do
      before do
        allow(merge_request).to receive(:diff_stats).and_return([double(path: 'abc.txt'), double(path: 'abc.xyz')])
      end

      it_behaves_like 'not tracked merge request unique event'
    end
  end

  describe '.track_milestone_changed_action' do
    subject { described_class.track_milestone_changed_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_MILESTONE_CHANGED_ACTION }
    end
  end

  describe '.track_labels_changed_action' do
    subject { described_class.track_labels_changed_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_LABELS_CHANGED_ACTION }
    end
  end

  describe '.track_loading_conflict_ui_action' do
    subject { described_class.track_loading_conflict_ui_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_LOAD_CONFLICT_UI_ACTION }
    end
  end

  describe '.track_resolve_conflict_action' do
    subject { described_class.track_resolve_conflict_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_RESOLVE_CONFLICT_ACTION }
    end
  end

  describe '.track_resolve_thread_in_issue_action' do
    subject { described_class.track_resolve_thread_in_issue_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_RESOLVE_THREAD_IN_ISSUE_ACTION }
    end
  end
end
