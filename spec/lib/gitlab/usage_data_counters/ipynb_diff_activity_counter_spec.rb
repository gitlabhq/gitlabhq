# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::IpynbDiffActivityCounter, :clean_gitlab_redis_shared_state do
  let(:user) { build(:user, id: 1) }
  let(:for_mr) { false }
  let(:for_commit) { false }
  let(:first_note) { build(:note, author: user, id: 1) }
  let(:second_note) { build(:note, author: user, id: 2) }

  before do
    allow(first_note).to receive(:for_merge_request?).and_return(for_mr)
    allow(second_note).to receive(:for_merge_request?).and_return(for_mr)
    allow(first_note).to receive(:for_commit?).and_return(for_commit)
    allow(second_note).to receive(:for_commit?).and_return(for_commit)
  end

  subject do
    described_class.note_created(first_note)
    described_class.note_created(first_note)
    described_class.note_created(second_note)
  end

  shared_examples_for 'an action that tracks events' do
    specify do
      expect { 2.times { subject } }
        .to change { event_count(action) }.by(2)
        .and change { event_count(per_user_action) }.by(1)
    end
  end

  shared_examples_for 'an action that does not track events' do
    specify do
      expect { 2.times { subject } }
        .to change { event_count(action) }.by(0)
        .and change { event_count(per_user_action) }.by(0)
    end
  end

  describe '#track_note_created_in_ipynb_diff' do
    context 'note is for commit' do
      let(:for_commit) { true }

      it_behaves_like 'an action that tracks events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_ACTION }
      end

      it_behaves_like 'an action that tracks events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_COMMIT_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_COMMIT_ACTION }
      end

      it_behaves_like 'an action that does not track events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_MR_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_MR_ACTION }
      end
    end

    context 'note is for MR' do
      let(:for_mr) { true }

      it_behaves_like 'an action that tracks events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_MR_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_MR_ACTION }
      end

      it_behaves_like 'an action that tracks events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_ACTION }
      end

      it_behaves_like 'an action that does not track events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_COMMIT_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_COMMIT_ACTION }
      end
    end

    context 'note is for neither MR nor Commit' do
      it_behaves_like 'an action that does not track events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_ACTION }
      end

      it_behaves_like 'an action that does not track events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_MR_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_MR_ACTION }
      end

      it_behaves_like 'an action that does not track events' do
        let(:action) { described_class::NOTE_CREATED_IN_IPYNB_DIFF_COMMIT_ACTION }
        let(:per_user_action) { described_class::USER_CREATED_NOTE_IN_IPYNB_DIFF_COMMIT_ACTION }
      end
    end
  end

  private

  def event_count(event_name)
    Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
      event_names: event_name,
      start_date: 2.weeks.ago,
      end_date: 2.weeks.from_now
    )
  end
end
