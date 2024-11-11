# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::EmailParticipants, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:work_item) { create(:work_item) }
  let_it_be(:target_work_item) { create(:work_item) }
  let_it_be(:participant1) { create(:issue_email_participant, issue: work_item, email: 'user1@example.com') }
  let_it_be(:participant2) { create(:issue_email_participant, issue: work_item, email: 'user2@example.com') }

  let(:params) { { operation: :move } }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#after_create' do
    context 'when target work item has email_participants widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:email_participants).and_return(true)
      end

      it 'copies email_participants from work_item to target_work_item' do
        expect(callback).to receive(:new_work_item_email_participants).and_call_original
        expect(::IssueEmailParticipant).to receive(:insert_all).and_call_original

        callback.after_create

        target_email_participants = target_work_item.reload.issue_email_participants.map(&:email)
        expect(target_email_participants).to match_array([participant1, participant2].map(&:email))
      end
    end

    context 'when operation is clone' do
      let(:params) { { operation: :clone } }

      it 'does not copy email_participants' do
        expect(callback).not_to receive(:new_work_item_email_participants)
        expect(::IssueEmailParticipant).not_to receive(:insert_all)

        callback.after_create

        expect(target_work_item.reload.issue_email_participants).to be_empty
      end
    end

    context 'when target work item does not have email_participants widget' do
      before do
        target_work_item.reload
        allow(target_work_item).to receive(:get_widget).with(:email_participants).and_return(false)
      end

      it 'does not copy email_participants' do
        expect(callback).not_to receive(:new_work_item_email_participants)
        expect(::IssueEmailParticipant).not_to receive(:insert_all)

        callback.after_create

        expect(target_work_item.reload.issue_email_participants).to be_empty
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'is defined and can be called' do
      expect { callback.post_move_cleanup }.not_to raise_error
    end

    it 'removes original work item email_participants' do
      callback.post_move_cleanup

      expect(work_item.issue_email_participants).to be_empty
    end
  end
end
