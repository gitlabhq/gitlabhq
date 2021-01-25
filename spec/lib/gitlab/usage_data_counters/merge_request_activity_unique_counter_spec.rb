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
    subject { described_class.track_create_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_CREATE_ACTION }
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
    subject { described_class.track_add_suggestion_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_ADD_SUGGESTION_ACTION }
    end
  end

  describe '.track_apply_suggestion_action' do
    subject { described_class.track_apply_suggestion_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_APPLY_SUGGESTION_ACTION }
    end
  end
end
