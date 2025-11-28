# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Notifications, feature_category: :team_planning do
  include SentNotificationHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:work_item) { create(:work_item) }
  let_it_be_with_reload(:subscription1) do
    create(:subscription, subscribable: work_item, user: create(:user), subscribed: true)
  end

  let_it_be_with_reload(:subscription2) do
    create(:subscription, subscribable: work_item, user: create(:user), subscribed: false)
  end

  let_it_be_with_reload(:sent_notification1) do
    create_sent_notification(project: work_item.project, noteable: work_item, recipient: create(:user))
  end

  let_it_be_with_reload(:sent_notification2) do
    create_sent_notification(project: work_item.project, noteable: work_item, recipient: create(:user))
  end

  let_it_be(:target_work_item) { create(:work_item) }
  let(:params) { { operation: :move } }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#after_save_commit' do
    context 'when target work item has notifications widget' do
      shared_examples 'notifies participants' do
        it 'notifies participants' do
          email_notification = case params[:operation]
                               when :move
                                 :issue_moved
                               when :clone
                                 :issue_cloned
                               end

          expect_next_instance_of(NotificationService) do |notification|
            expect(notification).to receive_message_chain(:async, email_notification.to_sym)
          end

          callback.after_save_commit
        end
      end

      before do
        allow(target_work_item).to receive(:get_widget).with(:notifications).and_return(true)
        allow(work_item).to receive(:from_service_desk?).and_return(true)
      end

      context 'when moving work item', :aggregate_failures do
        it 'copies notifications from work_item to target_work_item and deletes sent_notifications from source' do
          expect(callback).to receive(:new_work_item_subscriptions).and_call_original
          expect(callback).to receive(:new_work_item_sent_notifications).and_call_original
          expect(::Subscription).to receive(:insert_all).and_call_original
          expect(::PartitionedSentNotification).to receive(:insert_all).and_call_original

          expected_subscriptions = work_item.subscriptions.pluck(:user_id)
          expected_sent_notifications = work_item.partitioned_sent_notifications.pluck(:recipient_id)
          old_notification_ids = work_item.partitioned_sent_notifications.pluck(:id)

          expect do
            callback.after_save_commit
          end.to change { work_item.partitioned_sent_notifications.count }.by(-2)

          subscriptions = target_work_item.reload.subscriptions.pluck(:user_id)
          notification_recipients = target_work_item.reload.partitioned_sent_notifications.pluck(:recipient_id)
          new_notification_ids = target_work_item.partitioned_sent_notifications.pluck(:id)
          expect(subscriptions).to match_array(expected_subscriptions)
          expect(notification_recipients).to match_array(expected_sent_notifications)
          expect(new_notification_ids).not_to match_array(old_notification_ids)
          expect(target_work_item.partitioned_sent_notifications.pluck(:namespace_id).uniq).to contain_exactly(
            target_work_item.namespace_id
          )
        end

        it_behaves_like 'notifies participants'
      end

      context 'when cloning work item' do
        let(:params) { { operation: :clone } }

        it 'does not copy subscriptions or notifications' do
          expect(callback).not_to receive(:new_work_item_subscriptions)
          expect(callback).not_to receive(:new_work_item_sent_notifications)
          expect(::Subscription).not_to receive(:insert_all)
          expect(::PartitionedSentNotification).not_to receive(:insert_all)

          callback.after_save_commit

          expect(target_work_item.reload.subscriptions).to be_empty
          expect(target_work_item.reload.partitioned_sent_notifications).to be_empty
        end

        it_behaves_like 'notifies participants'
      end

      context 'when work item is not a service desk work item' do
        before do
          allow(work_item).to receive(:from_service_desk?).and_return(false)
        end

        it 'copies subscriptions but does not copy notifications' do
          expect(callback).to receive(:new_work_item_subscriptions).and_call_original
          expect(callback).not_to receive(:new_work_item_sent_notifications)
          expect(::Subscription).to receive(:insert_all).and_call_original
          expect(::PartitionedSentNotification).not_to receive(:insert_all)

          expected_subscriptions = work_item.subscriptions.pluck(:user_id)

          callback.after_save_commit

          subscriptions = target_work_item.reload.subscriptions.pluck(:user_id)
          expect(subscriptions).to match_array(expected_subscriptions)
          expect(target_work_item.reload.partitioned_sent_notifications).to be_empty
        end
      end
    end

    context 'when target work item does not have notifications widget' do
      before do
        target_work_item.reload
        allow(target_work_item).to receive(:get_widget).with(:notifications).and_return(false)
      end

      it 'does not copy subscriptions or notifications' do
        expect(callback).not_to receive(:new_work_item_subscriptions)
        expect(callback).not_to receive(:new_work_item_sent_notifications)
        expect(::Subscription).not_to receive(:insert_all)
        expect(::PartitionedSentNotification).not_to receive(:insert_all)

        callback.after_save_commit

        expect(target_work_item.reload.subscriptions).to be_empty
        expect(target_work_item.reload.partitioned_sent_notifications).to be_empty
      end

      it 'does not notify participants' do
        expect(NotificationService).not_to receive(:new)

        callback.after_save_commit
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'removes original work item notifications' do
      expect(work_item.subscriptions.count).to eq(2)
      expect(work_item.partitioned_sent_notifications.count).to eq(2)

      expect { callback.post_move_cleanup }.not_to raise_error

      expect(work_item.subscriptions).to be_empty
      expect(work_item.partitioned_sent_notifications).to be_empty
    end

    context 'when cleanup data in batches' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
      end

      it 'removes original work item notifications' do
        create(:subscription, subscribable: work_item, user: create(:user), subscribed: true)
        create(:subscription, subscribable: work_item, user: create(:user), subscribed: false)
        create_sent_notification(project: work_item.project, noteable: work_item, recipient: create(:user))
        create_sent_notification(project: work_item.project, noteable: work_item, recipient: create(:user))

        expect(work_item.subscriptions.count).to eq(4)
        expect(work_item.partitioned_sent_notifications.count).to eq(4)

        callback.post_move_cleanup

        expect(work_item.subscriptions).to be_empty
        expect(work_item.partitioned_sent_notifications).to be_empty
      end
    end
  end
end
