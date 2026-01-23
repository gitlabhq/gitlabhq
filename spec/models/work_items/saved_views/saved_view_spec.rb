# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::SavedView, feature_category: :portfolio_management do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:saved_view) { create(:saved_view, namespace: namespace) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:author).class_name('User').with_foreign_key(:created_by_id).optional }
    it { is_expected.to have_many(:user_saved_views).class_name('WorkItems::SavedViews::UserSavedView') }
    it { is_expected.to have_many(:subscribed_users).through(:user_saved_views).source(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(140) }
    it { is_expected.to validate_length_of(:description).is_at_most(140) }
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_numericality_of(:version).is_greater_than(0) }
    it { is_expected.to allow_value(true).for(:private) }
    it { is_expected.to allow_value(false).for(:private) }
    it { is_expected.not_to allow_value(nil).for(:private) }
  end

  describe '#unsubscribe_other_users!' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user_1) { create(:user) }
    let_it_be(:other_user_2) { create(:user) }

    let_it_be(:unrelated_user) { create(:user) }
    let_it_be(:unrelated_saved_view) { create(:saved_view, namespace: namespace) }
    let_it_be(:unrelated_user_saved_view) do
      create(:user_saved_view, saved_view: unrelated_saved_view, user: unrelated_user)
    end

    before do
      create(:user_saved_view, saved_view: saved_view, user: user)
      create(:user_saved_view, saved_view: saved_view, user: other_user_1)
      create(:user_saved_view, saved_view: saved_view, user: other_user_2)
    end

    it 'deletes subscriptions for all users except the specified user' do
      expect { saved_view.unsubscribe_other_users!(user: user) }
        .to change { saved_view.user_saved_views.count }.from(3).to(1)
        .and not_change { unrelated_saved_view.user_saved_views.count }
    end

    it 'keeps only the specified user subscribed' do
      saved_view.unsubscribe_other_users!(user: user)

      expect(saved_view.subscribed_users).to contain_exactly(user)
      expect(unrelated_saved_view.subscribed_users).to contain_exactly(unrelated_user)
    end

    context 'when the specified user is not subscribed' do
      let_it_be(:unsubscribed_user) { create(:user) }

      it 'deletes all subscriptions' do
        expect { saved_view.unsubscribe_other_users!(user: unsubscribed_user) }
          .to change { saved_view.user_saved_views.count }.from(3).to(0)
      end
    end

    context 'when there are no other subscriptions' do
      let_it_be(:no_subscription_saved_view) { create(:saved_view, namespace: namespace) }

      before do
        create(:user_saved_view, saved_view: no_subscription_saved_view, user: user)
      end

      it 'does not change the subscription count' do
        expect { no_subscription_saved_view.unsubscribe_other_users!(user: user) }
          .not_to change { no_subscription_saved_view.user_saved_views.count }
      end
    end

    it 'does not trigger N+1 queries' do
      control = ActiveRecord::QueryRecorder.new { saved_view.unsubscribe_other_users!(user: user) }

      5.times { create(:user_saved_view, saved_view: saved_view, user: create(:user)) }

      expect { saved_view.unsubscribe_other_users!(user: user) }.not_to exceed_query_limit(control)
    end
  end
end
