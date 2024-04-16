# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::Notifications, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:author) { create(:user, guest_of: project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project, author: author) }
  let_it_be(:current_user) { guest }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Callbacks::Notifications) } }
  let(:service) { described_class.new(issuable: work_item, current_user: current_user, params: params) }

  describe '#before_update_in_transaction' do
    let(:expected) { params[:subscribed] }

    subject(:update_notifications) { service.before_update }

    shared_examples 'failing to update subscription' do
      context 'when user is subscribed with a subscription record' do
        let_it_be(:subscription) { create_subscription(:subscribed) }

        it "does not update the work item's subscription" do
          expect do
            update_notifications
            subscription.reload
          end.to not_change { subscription.subscribed }
            .and(not_change { work_item.subscribed?(current_user, project) })
        end
      end

      context 'when user is subscribed by being a participant' do
        let_it_be(:current_user) { author }

        it 'does not create subscription record or change subscription state' do
          expect { update_notifications }
            .to not_change { Subscription.count }
            .and(not_change { work_item.subscribed?(current_user, project) })
        end
      end
    end

    shared_examples 'updating notifications subscription successfully' do
      it 'updates existing subscription record' do
        expect do
          update_notifications
          subscription.reload
        end.to change { subscription.subscribed }.to(expected)
          .and(change { work_item.subscribed?(current_user, project) }.to(expected))
      end
    end

    context 'when update fails' do
      context 'when user lack update_subscription permissions' do
        let_it_be(:params) { { subscribed: false } }

        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?)
            .with(current_user, :update_subscription, work_item)
            .and_return(false)
        end

        it_behaves_like 'failing to update subscription'
      end

      context 'when notifications params are not present' do
        let_it_be(:params) { {} }

        it_behaves_like 'failing to update subscription'
      end
    end

    context 'when update is successful' do
      context 'when subscribing' do
        let_it_be(:subscription) { create_subscription(:unsubscribed) }
        let(:params) { { subscribed: true } }

        it_behaves_like 'updating notifications subscription successfully'
      end

      context 'when unsubscribing' do
        let(:params) { { subscribed: false } }

        context 'when user is subscribed with a subscription record' do
          let_it_be(:subscription) { create_subscription(:subscribed) }

          it_behaves_like 'updating notifications subscription successfully'
        end

        context 'when user is subscribed by being a participant' do
          let_it_be(:current_user) { author }

          it 'creates a subscription with expected value' do
            expect { update_notifications }
              .to change { Subscription.count }.by(1)
              .and(change { work_item.subscribed?(current_user, project) }.to(expected))

            expect(Subscription.last.subscribed).to eq(expected)
          end
        end
      end
    end
  end

  def create_subscription(state)
    create(
      :subscription,
      project: project,
      user: current_user,
      subscribable: work_item,
      subscribed: (state == :subscribed)
    )
  end
end
