# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::UserAchievementPolicy, feature_category: :user_profile do
  let(:maintainer) { create(:user) }

  let(:group) { create(:group, :public) }

  let(:current_user) { create(:user) }
  let(:achievement) { create(:achievement, namespace: group) }
  let(:achievement_owner) { create(:user) }
  let(:user_achievement) { create(:user_achievement, achievement: achievement, user: achievement_owner) }

  before do
    group.add_maintainer(maintainer)
  end

  subject { described_class.new(current_user, user_achievement) }

  it 'is readable to everyone when user has public profile' do
    is_expected.to be_allowed(:read_user_achievement)
  end

  context 'when user has private profile' do
    before do
      achievement_owner.update!(private_profile: true)
    end

    context 'for achievement owner' do
      let(:current_user) { achievement_owner }

      it 'is visible' do
        is_expected.to be_allowed(:read_user_achievement)
      end
    end

    context 'for group maintainer' do
      let(:current_user) { maintainer }

      it 'is visible' do
        is_expected.to be_allowed(:read_user_achievement)
      end
    end

    context 'for others' do
      it 'is hidden' do
        is_expected.not_to be_allowed(:read_user_achievement)
      end
    end
  end

  context 'when group is private' do
    let(:group) { create(:group, :private) }

    context 'for achievement owner' do
      let(:current_user) { achievement_owner }

      it 'is visible' do
        is_expected.to be_allowed(:read_user_achievement)
      end
    end

    context 'for group maintainer' do
      let(:current_user) { maintainer }

      it 'is visible' do
        is_expected.to be_allowed(:read_user_achievement)
      end
    end

    context 'for others' do
      it 'is visible' do
        is_expected.to be_allowed(:read_user_achievement)
      end
    end
  end
end
