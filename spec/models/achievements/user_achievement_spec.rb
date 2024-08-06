# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::UserAchievement, type: :model, feature_category: :user_profile do
  describe 'associations' do
    it { is_expected.to belong_to(:achievement).inverse_of(:user_achievements).required }
    it { is_expected.to belong_to(:user).inverse_of(:user_achievements).required }

    it { is_expected.to belong_to(:awarded_by_user).class_name('User').inverse_of(:awarded_user_achievements).required }
    it { is_expected.to belong_to(:revoked_by_user).class_name('User').inverse_of(:revoked_user_achievements).optional }

    describe '#revoked?' do
      subject { achievement.revoked? }

      context 'when revoked' do
        let_it_be(:achievement) { create(:user_achievement, :revoked) }

        it { is_expected.to be true }
      end

      context 'when not revoked' do
        let_it_be(:achievement) { create(:user_achievement) }

        it { is_expected.to be false }
      end
    end
  end

  describe 'scopes' do
    let_it_be(:user_achievement) { create(:user_achievement) }
    let_it_be(:revoked_user_achievement) { create(:user_achievement, :revoked) }
    let_it_be(:hidden_user_achievement) { create(:user_achievement, show_on_profile: false) }

    describe '.not_revoked' do
      it 'only returns user achievements which have not been revoked' do
        expect(described_class.not_revoked).to contain_exactly(user_achievement, hidden_user_achievement)
      end
    end

    describe '.shown_on_profile' do
      it 'only returns user achievements which are shown on profiles' do
        expect(described_class.shown_on_profile).to contain_exactly(user_achievement, revoked_user_achievement)
      end
    end
  end

  describe 'validations' do
    it { is_expected.to allow_values([false, true]).for(:show_on_profile) }
    it { is_expected.not_to allow_value(nil).for(:show_on_profile) }
  end
end
