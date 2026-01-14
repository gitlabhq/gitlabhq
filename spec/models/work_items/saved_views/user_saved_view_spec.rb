# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::UserSavedView, feature_category: :portfolio_management do
  describe '.user_saved_view_limit' do
    let(:namespace) { build(:namespace) }

    it 'returns the correct value' do
      expect(described_class.user_saved_view_limit(namespace)).to eq(5)
    end
  end

  describe 'scopes' do
    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { create(:group) }
    let_it_be(:another_namespace) { create(:group) }
    let_it_be(:saved_view) { create(:saved_view, namespace: namespace) }
    let_it_be(:saved_view_in_another_namespace) { create(:saved_view, namespace: another_namespace) }
    let_it_be(:user_saved_view) { create(:user_saved_view, user: user, saved_view: saved_view, namespace: namespace) }
    let_it_be(:user_saved_view_in_another_namespace) do
      create(:user_saved_view, user: user, saved_view: saved_view_in_another_namespace, namespace: another_namespace)
    end

    describe '.in_namespace' do
      it 'returns user saved views for the given namespace' do
        result = described_class.in_namespace(namespace)

        expect(result).to contain_exactly(user_saved_view)
        expect(result).not_to include(user_saved_view_in_another_namespace)
      end
    end

    describe '.for_user' do
      it 'returns user saved views for the given user' do
        result = described_class.for_user(user)

        expect(result).to contain_exactly(user_saved_view, user_saved_view_in_another_namespace)
      end
    end

    describe '.for_saved_view' do
      it 'returns user saved views for the given saved view' do
        result = described_class.for_saved_view(saved_view)

        expect(result).to contain_exactly(user_saved_view)
      end
    end
  end

  describe '.relative_positioning_query_base' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:saved_view) { create(:saved_view, namespace: group) }
    let_it_be(:user_saved_view) { create(:user_saved_view, user: user, saved_view: saved_view, namespace: group) }

    it 'returns user saved views scoped by namespace and user' do
      result = described_class.relative_positioning_query_base(user_saved_view)

      expect(result).to contain_exactly(user_saved_view)
    end
  end

  describe '.relative_positioning_parent_column' do
    it 'returns user_id' do
      expect(described_class.relative_positioning_parent_column).to eq(:user_id)
    end
  end

  describe '#set_initial_position' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:saved_view) { create(:saved_view, namespace: group) }

    context 'when relative_position is nil' do
      it 'sets relative_position on create' do
        user_saved_view = create(:user_saved_view, user: user, saved_view: saved_view, namespace: group,
          relative_position: nil)

        expect(user_saved_view.relative_position).not_to be_nil
      end
    end

    context 'when relative_position is already set' do
      it 'does not change relative_position on create' do
        user_saved_view = create(:user_saved_view, user: user, saved_view: saved_view, namespace: group,
          relative_position: 1000)

        expect(user_saved_view.relative_position).to eq(1000)
      end
    end
  end
end
