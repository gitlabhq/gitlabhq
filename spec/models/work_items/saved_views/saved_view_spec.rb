# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::SavedView, feature_category: :portfolio_management do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:saved_view) { create(:saved_view, namespace: namespace) }
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:saved_view1) { create(:saved_view, namespace: group, name: 'SavedView1', author: user) }
  let_it_be(:saved_view2) { create(:saved_view, namespace: group, name: 'SavedView2', author: user) }
  let_it_be(:private_view) { create(:saved_view, namespace: group, author: other_user, private: true) }
  let_it_be(:other_view) { create(:saved_view, namespace: other_group) }

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

  describe '.in_namespace' do
    it 'returns saved views for the namespace' do
      expect(described_class.in_namespace(group)).to contain_exactly(saved_view1, saved_view2, private_view)
    end
  end

  describe '.subscribed_by' do
    let!(:user_saved_view) { create(:user_saved_view, user: user, saved_view: saved_view1, namespace: group) }

    it 'returns saved views subscribed by user' do
      expect(described_class.subscribed_by(user)).to contain_exactly(saved_view1)
    end
  end

  describe '.search' do
    it 'returns saved views matching name' do
      expect(described_class.search('SavedView1')).to contain_exactly(saved_view1)
    end
  end

  describe '.authored_by' do
    it 'returns saved views authored by user' do
      expect(described_class.authored_by(user)).to contain_exactly(saved_view1, saved_view2)
    end
  end

  describe '.private_only' do
    it 'returns only private saved views' do
      expect(described_class.private_only).to include(private_view)
      expect(described_class.private_only).not_to include(saved_view1, saved_view2)
    end
  end

  describe '.public_only' do
    it 'returns only public saved views' do
      expect(described_class.public_only).to include(saved_view1, saved_view2)
      expect(described_class.public_only).not_to include(private_view)
    end
  end

  describe '.visible_to' do
    context 'when user is provided' do
      it 'returns public views and user authored private views' do
        users_private_view = create(:saved_view, namespace: group, author: user, private: true)

        result = described_class.visible_to(user)

        expect(result).to include(saved_view1, saved_view2, users_private_view)
        expect(result).not_to include(private_view)
      end
    end

    context 'when user is nil' do
      it 'returns only public views' do
        result = described_class.visible_to(nil)

        expect(result).to include(saved_view1, saved_view2)
        expect(result).not_to include(private_view)
      end
    end
  end

  describe '.sort_by_attributes' do
    context 'when sort is :id' do
      it 'returns saved views sorted by id descending' do
        result = described_class.in_namespace(group).sort_by_attributes(:id)

        expect(result.to_a).to eq([private_view, saved_view2, saved_view1])
      end
    end

    context 'when sort is :relative_position' do
      let!(:user_saved_view1) do
        create(:user_saved_view, user: user, saved_view: saved_view1, namespace: group, relative_position: 1000)
      end

      let!(:user_saved_view2) do
        create(:user_saved_view, user: user, saved_view: saved_view2, namespace: group, relative_position: 2000)
      end

      context 'with user and scoped_to_subscribed' do
        it 'returns saved views sorted by relative position ascending' do
          result = described_class.sort_by_attributes(:relative_position, user: user, scoped_to_subscribed: true)

          expect(result.to_a).to eq([saved_view1, saved_view2])
        end
      end

      context 'without scoped_to_subscribed' do
        it 'falls back to id sort' do
          result = described_class.sort_by_attributes(:relative_position, user: user, scoped_to_subscribed: false)

          expect(result.to_a).to eq([other_view, private_view, saved_view2, saved_view1, saved_view])
        end
      end

      context 'without user' do
        it 'falls back to id sort' do
          result = described_class.sort_by_attributes(:relative_position, user: nil, scoped_to_subscribed: true)

          expect(result.to_a).to eq([other_view, private_view, saved_view2, saved_view1, saved_view])
        end
      end
    end
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

  describe '#allow_possible_spam?' do
    subject { saved_view.allow_possible_spam?(user) }

    context 'when saved view is public and namespace is public' do
      before do
        saved_view.private = false
        namespace.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
      end

      it { is_expected.to be(false) }
    end

    context 'when saved view is private' do
      before do
        saved_view.private = true
      end

      it { is_expected.to be(true) }
    end

    context 'when namespace is private' do
      before do
        saved_view.private = false
        namespace.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      it { is_expected.to be(true) }
    end

    context 'when global setting allows possible spam' do
      before do
        stub_application_setting(allow_possible_spam: true)
      end

      it { is_expected.to be(true) }
    end
  end
end
